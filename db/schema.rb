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

ActiveRecord::Schema[7.1].define(version: 2023_12_25_084838) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_stat_statements"
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

  create_table "customers", force: :cascade do |t|
    t.string "woo_id"
    t.string "first_name"
    t.string "last_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "email"
    t.string "phone"
  end

  create_table "franchises", force: :cascade do |t|
    t.string "title"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "payments", force: :cascade do |t|
    t.decimal "value", precision: 8, scale: 2
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "purchase_id", null: false
    t.datetime "payment_date", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.index ["purchase_id"], name: "index_payments_on_purchase_id"
  end

  create_table "product_brands", force: :cascade do |t|
    t.bigint "product_id"
    t.bigint "brand_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["brand_id"], name: "index_product_brands_on_brand_id"
    t.index ["product_id"], name: "index_product_brands_on_product_id"
  end

  create_table "product_colors", force: :cascade do |t|
    t.bigint "product_id"
    t.bigint "color_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["color_id"], name: "index_product_colors_on_color_id"
    t.index ["product_id"], name: "index_product_colors_on_product_id"
  end

  create_table "product_sales", force: :cascade do |t|
    t.decimal "price", precision: 8, scale: 2
    t.integer "qty"
    t.bigint "product_id", null: false
    t.bigint "sale_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "woo_id"
    t.bigint "variation_id"
    t.index ["product_id"], name: "index_product_sales_on_product_id"
    t.index ["sale_id"], name: "index_product_sales_on_sale_id"
    t.index ["variation_id"], name: "index_product_sales_on_variation_id"
  end

  create_table "product_sizes", force: :cascade do |t|
    t.bigint "product_id"
    t.bigint "size_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["product_id"], name: "index_product_sizes_on_product_id"
    t.index ["size_id"], name: "index_product_sizes_on_size_id"
  end

  create_table "product_suppliers", force: :cascade do |t|
    t.bigint "product_id"
    t.bigint "supplier_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["product_id"], name: "index_product_suppliers_on_product_id"
    t.index ["supplier_id"], name: "index_product_suppliers_on_supplier_id"
  end

  create_table "product_versions", force: :cascade do |t|
    t.bigint "product_id"
    t.bigint "version_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["product_id"], name: "index_product_versions_on_product_id"
    t.index ["version_id"], name: "index_product_versions_on_version_id"
  end

  create_table "products", force: :cascade do |t|
    t.string "title"
    t.bigint "franchise_id", null: false
    t.bigint "shape_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "woo_id"
    t.string "full_title"
    t.string "image"
    t.string "store_link"
    t.index ["franchise_id"], name: "index_products_on_franchise_id"
    t.index ["shape_id"], name: "index_products_on_shape_id"
  end

  create_table "purchases", force: :cascade do |t|
    t.bigint "supplier_id", null: false
    t.bigint "product_id"
    t.string "order_reference"
    t.decimal "item_price", precision: 8, scale: 2
    t.integer "amount"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "variation_id"
    t.datetime "purchase_date"
    t.index ["product_id"], name: "index_purchases_on_product_id"
    t.index ["supplier_id"], name: "index_purchases_on_supplier_id"
    t.index ["variation_id"], name: "index_purchases_on_variation_id"
  end

  create_table "sales", force: :cascade do |t|
    t.string "woo_id"
    t.string "status"
    t.decimal "discount_total", precision: 8, scale: 2
    t.decimal "shipping_total", precision: 8, scale: 2
    t.decimal "total", precision: 8, scale: 2
    t.string "company"
    t.string "address_1"
    t.string "address_2"
    t.string "city"
    t.string "state"
    t.string "postcode"
    t.string "country"
    t.string "note"
    t.bigint "customer_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "woo_created_at"
    t.datetime "woo_updated_at"
    t.index ["customer_id"], name: "index_sales_on_customer_id"
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

  create_table "variations", force: :cascade do |t|
    t.string "title"
    t.string "woo_id"
    t.bigint "size_id"
    t.bigint "version_id"
    t.bigint "color_id"
    t.bigint "product_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "store_link"
    t.index ["color_id"], name: "index_variations_on_color_id"
    t.index ["product_id"], name: "index_variations_on_product_id"
    t.index ["size_id"], name: "index_variations_on_size_id"
    t.index ["version_id"], name: "index_variations_on_version_id"
  end

  create_table "versions", force: :cascade do |t|
    t.string "value"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_foreign_key "payments", "purchases"
  add_foreign_key "product_brands", "brands"
  add_foreign_key "product_brands", "products"
  add_foreign_key "product_colors", "colors"
  add_foreign_key "product_colors", "products"
  add_foreign_key "product_sales", "products"
  add_foreign_key "product_sales", "sales"
  add_foreign_key "product_sales", "variations"
  add_foreign_key "product_sizes", "products"
  add_foreign_key "product_sizes", "sizes"
  add_foreign_key "product_suppliers", "products"
  add_foreign_key "product_suppliers", "suppliers"
  add_foreign_key "product_versions", "products"
  add_foreign_key "product_versions", "versions"
  add_foreign_key "products", "franchises"
  add_foreign_key "products", "shapes"
  add_foreign_key "purchases", "products"
  add_foreign_key "purchases", "suppliers"
  add_foreign_key "purchases", "variations"
  add_foreign_key "sales", "customers"
  add_foreign_key "variations", "colors"
  add_foreign_key "variations", "products"
  add_foreign_key "variations", "sizes"
  add_foreign_key "variations", "versions"
end
