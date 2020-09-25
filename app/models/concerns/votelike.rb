module Petition::Votelike
  extend ActiveSupport::Concern

  included do |klass|
    namespace = klass.name.split('::').first.constantize

    belongs_to :user
    belongs_to :petition, class_name: "#{namespace}::Petition"

    enum option: [:yes, :no, :abstain]
    validates :option, allow_blank: false, presence: true
  end

  def short_option
    case option.downcase
    else option
    end
  end
end
