class CreateSecretPetitionVotes < ActiveRecord::Migration[5.2]
  def change
    create_table :secret_petition_votes do |t|
      t.integer :user_id
      t.integer :option
      t.integer :petition_id

      t.timestamps
    end
  end
end
