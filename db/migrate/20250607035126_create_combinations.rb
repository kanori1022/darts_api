class CreateCombinations < ActiveRecord::Migration[8.0]
  def change
    create_table :combinations do |t|
      t.references :user, null: false, foreign_key: true
      t.string :title
      t.string :flight
      t.string :shaft
      t.string :barrel
      t.string :tip
      t.text :description

      t.timestamps
    end
  end
end
