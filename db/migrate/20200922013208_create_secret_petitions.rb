class CreateSecretPetitions < ActiveRecord::Migration[5.2]
  def change
    create_table :secret_petitions do |t|
      t.integer :chain_id
      t.integer :user_id
      t.string :title
      t.text :description
      t.integer :status
      t.float :tally_result_yes
      t.float :tally_result_abstain
      t.float :tally_result_no
      t.datetime :voting_start_time
      t.datetime :voting_end_time
      t.boolean :finalized
      
      t.timestamps
    end
  end
end
