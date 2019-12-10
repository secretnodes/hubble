class Common::Watch < ApplicationRecord
  belongs_to :chainlike, polymorphic: true
  belongs_to :watchable, polymorphic: true
  belongs_to :user
end
