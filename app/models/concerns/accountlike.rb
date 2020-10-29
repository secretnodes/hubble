module Accountlike
  extend ActiveSupport::Concern

  included do |klass|
    namespace = klass.name.deconstantize.constantize

    belongs_to :chain, class_name: "#{namespace}::Chain"
    belongs_to :validator, class_name: "#{namespace}::Validator", optional: true

    has_many :governance_deposits, class_name: "#{namespace}::Governance::Deposit"
    has_many :governance_votes, class_name: "#{namespace}::Governance::Vote"

    # Rails wouldn't let us name this transaction because there's already a '.transaction' method reserved
    has_and_belongs_to_many :txs, class_name: "#{namespace}::Transaction", join_table: "#{namespace.to_s.downcase}_accounts_#{namespace.to_s.downcase}_transactions"

    validates :address, allow_blank: false, presence: true, uniqueness: { scope: :chain }
    Gutentag::ActiveRecord.call self
  end

  def to_param; address; end

  def tags_as_string
    tag_names.join(", ")
  end

  def tags_as_string=(string)
    self.tag_names = string.gsub(' ', '').split(',')
  end
end
