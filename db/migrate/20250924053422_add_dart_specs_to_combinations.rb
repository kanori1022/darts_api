class AddDartSpecsToCombinations < ActiveRecord::Migration[8.0]
  def change
    add_column :combinations, :full_setting_length, :decimal
    add_column :combinations, :full_setting_weight, :decimal
    add_column :combinations, :barrel_weight, :decimal
    add_column :combinations, :barrel_max_diameter, :decimal
    add_column :combinations, :barrel_min_diameter, :decimal
  end
end
