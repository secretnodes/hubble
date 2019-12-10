class RenameParamsChanges < ActiveRecord::Migration[5.2]
  def change
    %w{ cosmos kava iris terra }.each do |network|
      remove_column :"#{network}_governance_proposals", :param_changes, :json, default: nil
      add_column :"#{network}_governance_proposals", :additional_data, :json, default: nil
    end
  end
end
