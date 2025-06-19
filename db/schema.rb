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

ActiveRecord::Schema[8.0].define(version: 2025_06_18_122536) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "active_storage_attachments", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.bigint "record_id", null: false
    t.string "record_type", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.string "content_type"
    t.datetime "created_at", null: false
    t.string "filename", null: false
    t.string "key", null: false
    t.text "metadata"
    t.string "service_name", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "audits", force: :cascade do |t|
    t.string "action"
    t.integer "associated_id"
    t.string "associated_type"
    t.integer "auditable_id"
    t.string "auditable_type"
    t.jsonb "audited_changes"
    t.string "comment"
    t.datetime "created_at"
    t.string "remote_address"
    t.string "request_uuid"
    t.integer "user_id"
    t.string "user_type"
    t.string "username"
    t.integer "version", default: 0
    t.index ["associated_type", "associated_id"], name: "associated_index"
    t.index ["auditable_type", "auditable_id", "version"], name: "auditable_index"
    t.index ["created_at"], name: "index_audits_on_created_at"
    t.index ["request_uuid"], name: "index_audits_on_request_uuid"
    t.index ["user_id", "user_type"], name: "user_index"
  end

  create_table "brands", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "title"
    t.datetime "updated_at", null: false
  end

  create_table "colors", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "value"
  end

  create_table "configs", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "sales_hook_status", default: 0
    t.datetime "shopify_products_sync"
    t.datetime "shopify_sales_sync"
    t.datetime "updated_at", null: false
  end

  create_table "customers", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email"
    t.string "first_name"
    t.string "last_name"
    t.string "phone"
    t.string "shopify_id"
    t.datetime "updated_at", null: false
    t.string "woo_id"
    t.index ["shopify_id"], name: "index_customers_on_shopify_id"
  end

  create_table "editions", force: :cascade do |t|
    t.bigint "color_id"
    t.datetime "created_at", null: false
    t.bigint "product_id", null: false
    t.string "shopify_id"
    t.bigint "size_id"
    t.string "sku"
    t.string "store_link"
    t.datetime "updated_at", null: false
    t.bigint "version_id"
    t.string "woo_id"
    t.index ["color_id"], name: "index_editions_on_color_id"
    t.index ["product_id"], name: "index_editions_on_product_id"
    t.index ["shopify_id"], name: "index_editions_on_shopify_id"
    t.index ["size_id"], name: "index_editions_on_size_id"
    t.index ["sku"], name: "index_editions_on_sku", unique: true
    t.index ["version_id"], name: "index_editions_on_version_id"
  end

  create_table "franchises", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "title"
    t.datetime "updated_at", null: false
  end

  create_table "friendly_id_slugs", force: :cascade do |t|
    t.datetime "created_at"
    t.string "scope"
    t.string "slug", null: false
    t.integer "sluggable_id", null: false
    t.string "sluggable_type", limit: 50
    t.index ["slug", "sluggable_type", "scope"], name: "index_friendly_id_slugs_on_slug_and_sluggable_type_and_scope", unique: true
    t.index ["slug", "sluggable_type"], name: "index_friendly_id_slugs_on_slug_and_sluggable_type"
    t.index ["sluggable_type", "sluggable_id"], name: "index_friendly_id_slugs_on_sluggable_type_and_sluggable_id"
  end

  create_table "notifications", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "event_type", default: 0, null: false
    t.string "name", null: false
    t.integer "status", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["event_type", "status"], name: "index_notifications_on_event_type_and_status"
  end

  create_table "payments", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "payment_date", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.bigint "purchase_id", null: false
    t.datetime "updated_at", null: false
    t.decimal "value", precision: 8, scale: 2
    t.index ["purchase_id"], name: "index_payments_on_purchase_id"
  end

  create_table "product_brands", force: :cascade do |t|
    t.bigint "brand_id"
    t.datetime "created_at", null: false
    t.bigint "product_id"
    t.datetime "updated_at", null: false
    t.index ["brand_id"], name: "index_product_brands_on_brand_id"
    t.index ["product_id"], name: "index_product_brands_on_product_id"
  end

  create_table "product_colors", force: :cascade do |t|
    t.bigint "color_id"
    t.datetime "created_at", null: false
    t.bigint "product_id"
    t.datetime "updated_at", null: false
    t.index ["color_id"], name: "index_product_colors_on_color_id"
    t.index ["product_id"], name: "index_product_colors_on_product_id"
  end

  create_table "product_sizes", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "product_id"
    t.bigint "size_id"
    t.datetime "updated_at", null: false
    t.index ["product_id"], name: "index_product_sizes_on_product_id"
    t.index ["size_id"], name: "index_product_sizes_on_size_id"
  end

  create_table "product_suppliers", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "product_id"
    t.bigint "supplier_id"
    t.datetime "updated_at", null: false
    t.index ["product_id"], name: "index_product_suppliers_on_product_id"
    t.index ["supplier_id"], name: "index_product_suppliers_on_supplier_id"
  end

  create_table "product_versions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "product_id"
    t.datetime "updated_at", null: false
    t.bigint "version_id"
    t.index ["product_id"], name: "index_product_versions_on_product_id"
    t.index ["version_id"], name: "index_product_versions_on_version_id"
  end

  create_table "products", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "franchise_id", null: false
    t.string "full_title"
    t.string "image"
    t.bigint "shape_id", null: false
    t.string "shopify_id"
    t.string "sku"
    t.string "slug"
    t.string "store_link"
    t.string "title"
    t.datetime "updated_at", null: false
    t.string "woo_id"
    t.index ["franchise_id"], name: "index_products_on_franchise_id"
    t.index ["shape_id"], name: "index_products_on_shape_id"
    t.index ["shopify_id"], name: "index_products_on_shopify_id"
    t.index ["sku"], name: "index_products_on_sku", unique: true
    t.index ["slug"], name: "index_products_on_slug", unique: true
  end

  create_table "purchase_items", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.decimal "expenses", precision: 8, scale: 2
    t.integer "height"
    t.integer "length"
    t.bigint "purchase_id"
    t.bigint "sale_item_id"
    t.bigint "shipping_company_id"
    t.decimal "shipping_price", precision: 8, scale: 2
    t.string "tracking_number"
    t.datetime "updated_at", null: false
    t.bigint "warehouse_id", null: false
    t.integer "weight"
    t.integer "width"
    t.index ["purchase_id"], name: "index_purchase_items_on_purchase_id"
    t.index ["sale_item_id"], name: "index_purchase_items_on_sale_item_id"
    t.index ["shipping_company_id"], name: "index_purchase_items_on_shipping_company_id"
    t.index ["warehouse_id"], name: "index_purchase_items_on_warehouse_id"
  end

  create_table "purchases", force: :cascade do |t|
    t.integer "amount"
    t.datetime "created_at", null: false
    t.bigint "edition_id"
    t.decimal "item_price", precision: 8, scale: 2
    t.string "order_reference"
    t.bigint "product_id"
    t.datetime "purchase_date"
    t.string "slug"
    t.bigint "supplier_id", null: false
    t.string "synced"
    t.datetime "updated_at", null: false
    t.index ["edition_id"], name: "index_purchases_on_edition_id"
    t.index ["product_id"], name: "index_purchases_on_product_id"
    t.index ["slug"], name: "index_purchases_on_slug", unique: true
    t.index ["supplier_id"], name: "index_purchases_on_supplier_id"
  end

  create_table "sale_items", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "edition_id"
    t.decimal "price", precision: 8, scale: 2
    t.bigint "product_id", null: false
    t.integer "purchased_products_count", default: 0, null: false
    t.integer "qty"
    t.bigint "sale_id", null: false
    t.string "shopify_id"
    t.datetime "updated_at", null: false
    t.string "woo_id"
    t.index ["edition_id"], name: "index_sale_items_on_edition_id"
    t.index ["product_id"], name: "index_sale_items_on_product_id"
    t.index ["sale_id"], name: "index_sale_items_on_sale_id"
    t.index ["shopify_id"], name: "index_sale_items_on_shopify_id"
    t.index ["woo_id"], name: "index_sale_items_on_woo_id", unique: true
  end

  create_table "sales", force: :cascade do |t|
    t.string "address_1"
    t.string "address_2"
    t.string "cancel_reason"
    t.datetime "cancelled_at"
    t.string "city"
    t.boolean "closed", default: false
    t.datetime "closed_at"
    t.string "company"
    t.boolean "confirmed", default: false
    t.string "country"
    t.datetime "created_at", null: false
    t.bigint "customer_id", null: false
    t.decimal "discount_total", precision: 8, scale: 2
    t.string "financial_status"
    t.string "fulfillment_status"
    t.string "note"
    t.string "postcode"
    t.string "return_status"
    t.decimal "shipping_total", precision: 8, scale: 2
    t.datetime "shopify_created_at"
    t.string "shopify_id"
    t.string "shopify_name"
    t.datetime "shopify_updated_at"
    t.string "slug"
    t.string "state"
    t.string "status"
    t.decimal "total", precision: 8, scale: 2
    t.datetime "updated_at", null: false
    t.datetime "woo_created_at"
    t.string "woo_id"
    t.datetime "woo_updated_at"
    t.index ["customer_id"], name: "index_sales_on_customer_id"
    t.index ["shopify_id"], name: "index_sales_on_shopify_id"
    t.index ["slug"], name: "index_sales_on_slug", unique: true
  end

  create_table "sessions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "ip_address"
    t.datetime "updated_at", null: false
    t.string "user_agent"
    t.bigint "user_id", null: false
    t.index ["user_id"], name: "index_sessions_on_user_id"
  end

  create_table "shapes", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "title"
    t.datetime "updated_at", null: false
  end

  create_table "shipping_companies", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name"
    t.string "tracking_url"
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_shipping_companies_on_name", unique: true
  end

  create_table "shops", force: :cascade do |t|
    t.string "access_scopes"
    t.datetime "created_at", null: false
    t.string "shopify_domain", null: false
    t.string "shopify_token", null: false
    t.datetime "updated_at", null: false
    t.index ["shopify_domain"], name: "index_shops_on_shopify_domain", unique: true
  end

  create_table "sizes", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "value"
    t.index ["value"], name: "index_sizes_on_value", unique: true
  end

  create_table "suppliers", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "slug"
    t.string "title"
    t.datetime "updated_at", null: false
    t.index ["slug"], name: "index_suppliers_on_slug", unique: true
  end

  create_table "users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email_address", null: false
    t.string "password_digest", null: false
    t.datetime "updated_at", null: false
    t.index ["email_address"], name: "index_users_on_email_address", unique: true
  end

  create_table "versions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "value"
  end

  create_table "warehouse_transitions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "from_warehouse_id"
    t.bigint "notification_id", null: false
    t.bigint "to_warehouse_id"
    t.datetime "updated_at", null: false
    t.index ["from_warehouse_id"], name: "index_warehouse_transitions_on_from_warehouse_id"
    t.index ["notification_id", "from_warehouse_id", "to_warehouse_id"], name: "index_warehouse_transitions_uniqueness", unique: true
    t.index ["notification_id"], name: "index_warehouse_transitions_on_notification_id"
    t.index ["to_warehouse_id"], name: "index_warehouse_transitions_on_to_warehouse_id"
  end

  create_table "warehouses", force: :cascade do |t|
    t.string "cbm"
    t.string "container_tracking_number"
    t.string "courier_tracking_url"
    t.datetime "created_at", null: false
    t.string "external_name"
    t.boolean "is_default", default: false, null: false
    t.string "name"
    t.integer "position", default: 1, null: false
    t.datetime "updated_at", null: false
    t.index ["is_default"], name: "index_warehouses_on_is_default", unique: true, where: "(is_default = true)"
    t.index ["position"], name: "index_warehouses_on_position", unique: true
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "editions", "colors"
  add_foreign_key "editions", "products"
  add_foreign_key "editions", "sizes"
  add_foreign_key "editions", "versions"
  add_foreign_key "payments", "purchases"
  add_foreign_key "product_brands", "brands"
  add_foreign_key "product_brands", "products"
  add_foreign_key "product_colors", "colors"
  add_foreign_key "product_colors", "products"
  add_foreign_key "product_sizes", "products"
  add_foreign_key "product_sizes", "sizes"
  add_foreign_key "product_suppliers", "products"
  add_foreign_key "product_suppliers", "suppliers"
  add_foreign_key "product_versions", "products"
  add_foreign_key "product_versions", "versions"
  add_foreign_key "products", "franchises"
  add_foreign_key "products", "shapes"
  add_foreign_key "purchase_items", "purchases"
  add_foreign_key "purchase_items", "sale_items"
  add_foreign_key "purchase_items", "shipping_companies"
  add_foreign_key "purchase_items", "warehouses"
  add_foreign_key "purchases", "editions"
  add_foreign_key "purchases", "products"
  add_foreign_key "purchases", "suppliers"
  add_foreign_key "sale_items", "editions"
  add_foreign_key "sale_items", "products"
  add_foreign_key "sale_items", "sales"
  add_foreign_key "sales", "customers"
  add_foreign_key "sessions", "users"
  add_foreign_key "warehouse_transitions", "notifications"
  add_foreign_key "warehouse_transitions", "warehouses", column: "from_warehouse_id"
  add_foreign_key "warehouse_transitions", "warehouses", column: "to_warehouse_id"
end
