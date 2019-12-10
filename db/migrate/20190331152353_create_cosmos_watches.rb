class CreateCosmosWatches < ActiveRecord::Migration[5.2]
  def change
    create_table :cosmos_watches do |t|
      t.references :chain, index: true
      t.references :watchable, polymorphic: true, null: false
      t.references :user, null: false
      t.timestamps
    end
  end
end
