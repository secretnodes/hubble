class AddCurrentStatusToSyncLogs < ActiveRecord::Migration[5.2]
  def change
    add_column :stats_sync_logs, :current_status, :string
  end
end
