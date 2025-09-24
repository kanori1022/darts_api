# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.0].define(version: 2025_09_24_053422) do
  create_table "active_storage_attachments", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.string "service_name", null: false
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "combinations", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "title"
    t.string "flight"
    t.string "shaft"
    t.string "barrel"
    t.string "tip"
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "favorites_count"
    t.decimal "full_setting_length", precision: 10
    t.decimal "full_setting_weight", precision: 10
    t.decimal "barrel_weight", precision: 10
    t.decimal "barrel_max_diameter", precision: 10
    t.decimal "barrel_min_diameter", precision: 10
    t.index ["user_id"], name: "index_combinations_on_user_id"
  end

  create_table "favorites", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "combination_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["combination_id"], name: "index_favorites_on_combination_id"
    t.index ["user_id"], name: "index_favorites_on_user_id"
  end

  create_table "taggings", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.bigint "tag_id", null: false
    t.bigint "combination_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["combination_id"], name: "index_taggings_on_combination_id"
    t.index ["tag_id", "combination_id"], name: "index_taggings_on_tag_id_and_combination_id", unique: true
    t.index ["tag_id"], name: "index_taggings_on_tag_id"
  end

  create_table "tags", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_tags_on_name", unique: true
  end

  create_table "users", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.string "firebase_uid"
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "introduction"
    t.string "header_gradient_from"
    t.string "header_gradient_to"
  end

  create_table "view_histories", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "combination_id", null: false
    t.datetime "viewed_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["combination_id"], name: "index_view_histories_on_combination_id"
    t.index ["user_id", "combination_id"], name: "index_view_histories_on_user_id_and_combination_id", unique: true
    t.index ["user_id", "viewed_at"], name: "index_view_histories_on_user_id_and_viewed_at"
    t.index ["user_id"], name: "index_view_histories_on_user_id"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "combinations", "users"
  add_foreign_key "favorites", "combinations"
  add_foreign_key "favorites", "users"
  add_foreign_key "taggings", "combinations"
  add_foreign_key "taggings", "tags"
  add_foreign_key "view_histories", "combinations"
  add_foreign_key "view_histories", "users"
end
