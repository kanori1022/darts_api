class AddFavoritesCountToCombinations < ActiveRecord::Migration[8.0]
  def change
    add_column :combinations, :favorites_count, :integer, default: 0, null: false
  end
end
