class AddChangesToGovernanceProposals < ActiveRecord::Migration[5.2]
  def change
    %w{ cosmos kava iris terra }.each do |network|
      add_column :"#{network}_governance_proposals", :param_changes, :json, default: nil
    end
  end
end
