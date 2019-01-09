class AddDefaultCurrentVotingPower < ActiveRecord::Migration[5.2]
  def change
    change_column :cosmos_validators, :current_voting_power, :bigint, default: 0
  end
end
