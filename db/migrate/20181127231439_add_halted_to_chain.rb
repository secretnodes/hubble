class AddHaltedToChain < ActiveRecord::Migration[5.2]
  def change
    add_column :cosmos_chains, :halted, :boolean, default: false
    add_column :cosmos_chains, :halted_at, :datetime
    add_column :cosmos_chains, :last_round_state, :string, default: ""
  end
end
