class CreateTaggings < ActiveRecord::Migration[8.0]
  def change
    create_table :taggings do |t|
      t.references :tag, null: false, foreign_key: true
      t.references :combination, null: false, foreign_key: true

      t.timestamps
    end

    # 同じcombinationに同じtagが重複して登録されるのを防ぐ
    add_index :taggings, [:tag_id, :combination_id], unique: true
  end
end
