class AddFoundationFieldsToPetitions < ActiveRecord::Migration[6.0]
  def change
    add_column :secret_petitions, :petition_type, :integer, default: 0
    add_column :secret_petitions, :amount, :integer, default: 0
    add_column :secret_petitions, :contact_info, :string
  end
end
