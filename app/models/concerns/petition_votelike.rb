module PetitionVotelike
  extend ActiveSupport::Concern

  included do |klass|
    namespace = klass.name.split('::').first.constantize

    belongs_to :user
    belongs_to :petition, class_name: "#{namespace}::Petition"

    validates :option, allow_blank: false, presence: true
    validates :user_id, uniqueness: { scope: :petition }
    before_save :update_tally_result

  end

  def update_tally_result
    if option_changed? && !new_record?
      old_option = changes['option'][0]
      petition["tally_result_#{old_option}"] -= 1
    end
    petition["tally_result_#{option}"] += 1
    petition.save!
  end
end
