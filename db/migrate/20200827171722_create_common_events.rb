class CreateCommonEvents < ActiveRecord::Migration[5.2]
  def change
    create_table :common_events do |t|
      t.string :type
      t.bigint :height
      t.datetime :timestamp
      t.integer :chainlike_id
      t.integer :validatorlike_id
      t.jsonb :data
      t.string :chainlike_type
      t.string :validatorlike_type
      t.string :accountlike_type
      t.integer :accountlike_id
      t.string :proposallike_type
      t.integer :proposallike_id
      t.string :votelike_type
      t.integer :votelike_id
      t.string :transactionlike_type
      t.integer :transactionlike_id

      t.timestamps
    end
  end
end
