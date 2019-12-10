class AddFrozenToProposals < ActiveRecord::Migration[5.2]
  def change
    %w{ cosmos iris terra kava }.each do |network|
      add_column :"#{network}_governance_proposals", :finalized, :boolean, default: false
    end
  end
end
