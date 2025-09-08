class CreateViewHistories < ActiveRecord::Migration[7.1]
  def change
    create_table :view_histories do |t|
      t.references :user, null: false, foreign_key: true
      t.references :combination, null: false, foreign_key: true
      t.datetime :viewed_at, null: false

      t.timestamps
    end

    add_index :view_histories, [:user_id, :combination_id], unique: true
    add_index :view_histories, [:user_id, :viewed_at]
  end
end
