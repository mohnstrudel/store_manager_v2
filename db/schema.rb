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

ActiveRecord::Schema[7.1].define(version: 2024_08_01_122749) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
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

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

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

  create_table "configs", force: :cascade do |t|
    t.integer "sales_hook_status", default: 0
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

  create_table "friendly_id_slugs", force: :cascade do |t|
    t.string "slug", null: false
    t.integer "sluggable_id", null: false
    t.string "sluggable_type", limit: 50
    t.string "scope"
    t.datetime "created_at"
    t.index ["slug", "sluggable_type", "scope"], name: "index_friendly_id_slugs_on_slug_and_sluggable_type_and_scope", unique: true
    t.index ["slug", "sluggable_type"], name: "index_friendly_id_slugs_on_slug_and_sluggable_type"
    t.index ["sluggable_type", "sluggable_id"], name: "index_friendly_id_slugs_on_sluggable_type_and_sluggable_id"
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
    t.index ["woo_id"], name: "index_product_sales_on_woo_id", unique: true
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
    t.string "slug"
    t.string "sku"
    t.index ["franchise_id"], name: "index_products_on_franchise_id"
    t.index ["shape_id"], name: "index_products_on_shape_id"
    t.index ["sku"], name: "index_products_on_sku", unique: true
    t.index ["slug"], name: "index_products_on_slug", unique: true
  end

  create_table "purchased_products", force: :cascade do |t|
    t.bigint "warehouse_id", null: false
    t.integer "weight"
    t.integer "length"
    t.integer "width"
    t.integer "height"
    t.decimal "price", precision: 8, scale: 2
    t.decimal "shipping_price", precision: 8, scale: 2
    t.string "tracking_number"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "purchase_id"
    t.index ["purchase_id"], name: "index_purchased_products_on_purchase_id"
    t.index ["warehouse_id"], name: "index_purchased_products_on_warehouse_id"
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
    t.string "synced"
    t.string "slug"
    t.index ["product_id"], name: "index_purchases_on_product_id"
    t.index ["slug"], name: "index_purchases_on_slug", unique: true
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
    t.string "slug"
    t.index ["customer_id"], name: "index_sales_on_customer_id"
    t.index ["slug"], name: "index_sales_on_slug", unique: true
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
    t.index ["value"], name: "index_sizes_on_value", unique: true
  end

  create_table "suppliers", force: :cascade do |t|
    t.string "title"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "slug"
    t.index ["slug"], name: "index_suppliers_on_slug", unique: true
  end

  create_table "variations", force: :cascade do |t|
    t.string "woo_id"
    t.bigint "size_id"
    t.bigint "version_id"
    t.bigint "color_id"
    t.bigint "product_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "store_link"
    t.string "sku"
    t.index ["color_id"], name: "index_variations_on_color_id"
    t.index ["product_id"], name: "index_variations_on_product_id"
    t.index ["size_id"], name: "index_variations_on_size_id"
    t.index ["sku"], name: "index_variations_on_sku", unique: true
    t.index ["version_id"], name: "index_variations_on_version_id"
  end

  create_table "versions", force: :cascade do |t|
    t.string "value"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "warehouses", force: :cascade do |t|
    t.string "name"
    t.string "external_name"
    t.string "container_tracking_number"
    t.string "courier_tracking_url"
    t.string "cbm"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
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
  add_foreign_key "purchased_products", "purchases"
  add_foreign_key "purchased_products", "warehouses"
  add_foreign_key "purchases", "products"
  add_foreign_key "purchases", "suppliers"
  add_foreign_key "purchases", "variations"
  add_foreign_key "sales", "customers"
  add_foreign_key "variations", "colors"
  add_foreign_key "variations", "products"
  add_foreign_key "variations", "sizes"
  add_foreign_key "variations", "versions"
end
