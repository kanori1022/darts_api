class AddHeaderGradientToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :header_gradient_from, :string
    add_column :users, :header_gradient_to, :string
  end
end
