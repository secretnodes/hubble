class IncreaseVotingPowerSize < ActiveRecord::Migration[5.2]
  def change
    change_column :cosmos_validators, :current_voting_power, :integer, limit: 8
  end
end
