class AddRoleToUsers < ActiveRecord::Migration[6.0]
  def change
    add_column :users, :role, :integer, default: 0, null: false
    add_column :users, :committee_member, :boolean, default: false, null: false
    add_column :users, :puzzle_staker, :boolean, default: false, null: false
  end
end
