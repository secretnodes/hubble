class CreateSecretPetitions < ActiveRecord::Migration[5.2]
  def change
    create_table :secret_petitions do |t|
      t.integer :chain_id
      t.integer :user_id
      t.string :title
      t.text :description
      t.integer :status, default: :voting_period, null: false
      t.decimal :tally_result_yes, default: 0, null: false
      t.decimal :tally_result_abstain, default: 0, null: false
      t.decimal :tally_result_no, default: 0, null: false
      t.datetime :voting_start_time
      t.datetime :voting_end_time
      t.boolean :finalized, default: false, null: false
      
      t.timestamps
    end
  end
end
