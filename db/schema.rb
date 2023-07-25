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

ActiveRecord::Schema[7.0].define(version: 2023_07_21_092423) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "brands", force: :cascade do |t|
    t.string "title"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "colors", force: :cascade do |t|
    t.string "value"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "franchises", force: :cascade do |t|
    t.string "title"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "products", force: :cascade do |t|
    t.string "title"
    t.bigint "supplier_id", null: false
    t.bigint "brand_id", null: false
    t.bigint "franchise_id", null: false
    t.bigint "size_id", null: false
    t.bigint "color_id", null: false
    t.bigint "version_id", null: false
    t.bigint "shape_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["brand_id"], name: "index_products_on_brand_id"
    t.index ["color_id"], name: "index_products_on_color_id"
    t.index ["franchise_id"], name: "index_products_on_franchise_id"
    t.index ["shape_id"], name: "index_products_on_shape_id"
    t.index ["size_id"], name: "index_products_on_size_id"
    t.index ["supplier_id"], name: "index_products_on_supplier_id"
    t.index ["version_id"], name: "index_products_on_version_id"
  end

  create_table "shapes", force: :cascade do |t|
    t.string "title"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "sizes", force: :cascade do |t|
    t.string "value"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "suppliers", force: :cascade do |t|
    t.string "title"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "versions", force: :cascade do |t|
    t.string "value"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_foreign_key "products", "brands"
  add_foreign_key "products", "colors"
  add_foreign_key "products", "franchises"
  add_foreign_key "products", "shapes"
  add_foreign_key "products", "sizes"
  add_foreign_key "products", "suppliers"
  add_foreign_key "products", "versions"
end
