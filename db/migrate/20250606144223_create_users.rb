class CreateUsers < ActiveRecord::Migration[8.0]
  def change
    create_table :users do |t|
      t.string :firebase_uid
      t.string :name

      t.timestamps
    end
  end
end
