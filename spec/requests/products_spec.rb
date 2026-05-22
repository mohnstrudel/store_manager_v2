# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Products" do
  before { sign_in_as_admin }

  describe "GET /products" do
    it "renders the index Inertia component with pagination and search" do
      product = create(:product)

      get products_path

      expect(response).to have_http_status(:ok)
      expect_inertia.to render_component("Products/Index")
      expect_inertia.to have_props(
        pagination: {current_page: 1, total_pages: 1, total_count: 1, limit: 50},
        search: {q: ""},
        last_sync_at: nil
      )

      first_props = inertia.props[:products].first
      expect(first_props[:id]).to eq(product.id)
      expect(first_props[:full_title]).to eq(product.full_title)
      expect(first_props[:path]).to eq(product_path(product))
    end

    it "filters products by search query" do
      matching = create(:product, title: "Pikachu")
      _other = create(:product, title: "Charmander")

      get products_path, params: {q: "Pikachu"}

      expect_inertia.to have_props(search: {q: "Pikachu"})
      expect(inertia.props[:products].map { |p| p[:id] }).to eq([matching.id])
    end
  end

  describe "GET /products/:id" do
    it "renders the show Inertia component with product data" do
      product = create(:product)

      get product_path(product)

      expect(response).to have_http_status(:ok)
      expect_inertia.to render_component("Products/Show")

      product_props = inertia.props[:product]
      expect(product_props[:id]).to eq(product.id)
      expect(product_props[:title]).to eq(product.title)
      expect(product_props[:full_title]).to eq(product.full_title)
      expect(product_props[:franchise][:title]).to eq(product.franchise.title)
    end

    it "includes active sales, completed sales, and purchases in props" do
      product = create(:product)
      variant = create(:variant, product:)
      active_sale = create(:sale, status: "processing")
      completed_sale = create(:sale, status: "completed")

      create(:sale_item, product:, variant:, sale: active_sale, qty: 1)
      create(:sale_item, product:, variant:, sale: completed_sale, qty: 2)
      create(:purchase, product:, variant:, amount: 3, item_price: 12.5)

      get product_path(product)

      expect(response).to have_http_status(:ok)
      expect(inertia.props[:active_sales].length).to eq(1)
      expect(inertia.props[:completed_sales].length).to eq(1)
      expect(inertia.props[:purchases].length).to eq(1)
    end

    it "includes store_infos tags in the show props" do
      product = create(:product)
      shopify_info = product.store_infos.shopify.first
      shopify_info.update(tag_list: "featured, new")

      get product_path(product)

      product_props = inertia.props[:product]
      expect(product_props[:shopify_info][:tag_list]).to include("featured", "new")
    end
  end

  describe "GET /products/new" do
    it "renders the new Inertia component with form options" do
      franchise = create(:franchise)

      get new_product_path

      expect(response).to have_http_status(:ok)
      expect_inertia.to render_component("Products/New")

      product_props = inertia.props[:product]
      expect(product_props[:id]).to be_nil
      expect(product_props[:variants].length).to eq(1)
      expect(product_props[:variants].first[:size_id]).to be_nil
      expect(product_props[:variants].first[:version_id]).to be_nil
      expect(product_props[:variants].first[:color_id]).to be_nil

      options = inertia.props[:options]
      expect(options[:franchises].map { |f| f[:value] }).to include(franchise.id)
      expect(options[:shapes]).to eq(Product.shape_options)
    end
  end

  describe "GET /products/:id/edit" do
    it "renders the edit Inertia component with product data and options" do
      product = create(:product)

      get edit_product_path(product)

      expect(response).to have_http_status(:ok)
      expect_inertia.to render_component("Products/Edit")

      product_props = inertia.props[:product]
      expect(product_props[:id]).to eq(product.id)
      expect(product_props[:title]).to eq(product.title)
      expect(product_props[:franchise_id]).to eq(product.franchise_id)

      expect(inertia.props[:options]).to be_a(Hash)
    end
  end

  describe "POST /products" do
    let(:franchise) { create(:franchise) }

    it "creates a product and redirects to show" do
      expect {
        post products_path, params: {
          product: {
            title: "New Figure",
            franchise_id: franchise.id,
            shape: "Statue"
          }
        }
      }.to change(Product, :count).by(1)

      expect(response).to redirect_to(product_path(Product.last))
      expect(flash[:notice]).to eq("Product was successfully created")
    end

    it "creates a product with nested variants, store infos, and an initial purchase" do
      brand = create(:brand, title: "Featured Brand")
      size = create(:size, value: "Large")
      version = create(:version, value: "Deluxe")
      color = create(:color, value: "Red")
      supplier = create(:supplier)
      warehouse = create(:warehouse, is_default: true)

      expect {
        post products_path, params: {
          product: {
            title: "Nested Product",
            description: "<p>Product description</p>",
            franchise_id: franchise.id,
            shape: "Bust",
            brand_ids: [brand.id]
          },
          variants: {
            "0" => {
              sku: "nested-product-variant",
              size_id: size.id,
              version_id: version.id,
              color_id: color.id,
              purchase_cost: "9.99",
              selling_price: "19.99",
              weight: "1.5",
              _destroy: "0"
            }
          },
          store_infos: {
            "0" => {
              store_name: "shopify",
              tag_list: "featured, new",
              _destroy: "0"
            }
          },
          purchase: {
            supplier_id: supplier.id,
            order_reference: "PO-42",
            item_price: "15",
            amount: "2",
            warehouse_id: warehouse.id,
            payment_value: "30"
          }
        }
      }.to change(Product, :count).by(1)
        .and change(Variant, :count).by(2)
        .and change(StoreInfo, :count).by(1)
        .and change(Purchase, :count).by(1)

      created_product = Product.find_by!(title: "Nested Product")
      purchase = created_product.purchases.last

      expect(response).to redirect_to(product_path(created_product))
      expect(created_product.brands).to match_array([brand])
      expect(created_product.description.body.to_html).to include("Product description")
      expect(created_product.sizes).to match_array([size])
      expect(created_product.versions).to match_array([version])
      expect(created_product.colors).to match_array([color])
      expect(created_product.store_infos.shopify.first.tag_list).to eq(["featured", "new"])
      expect(purchase.supplier).to eq(supplier)
      expect(purchase.purchase_items.count).to eq(2)
      expect(purchase.purchase_items.pluck(:warehouse_id).uniq).to eq([warehouse.id])
      expect(purchase.payments.pluck(:value)).to eq([BigDecimal("30")])
    end

    it "redirects to new with errors when title is blank" do
      post products_path, params: {
        product: {title: "", franchise_id: franchise.id, shape: "Statue"}
      }

      expect(response).to redirect_to(new_product_path)

      follow_redirect!

      expect(response).to have_http_status(:ok)
      expect_inertia.to render_component("Products/New")
      expect(inertia.props[:errors]).to be_present
    end
  end

  describe "PATCH /products/:id" do
    let(:product) { create(:product) }

    it "updates the product and redirects to show" do
      patch product_path(product), params: {
        product: {
          title: product.title,
          franchise_id: product.franchise_id,
          shape: product.shape
        }
      }

      expect(response).to redirect_to(product_path(product.reload))
      expect(product.title).to eq(product.title)
    end

    it "redirects to edit with errors when title is blank" do
      patch product_path(product), params: {
        product: {title: "", franchise_id: product.franchise_id, shape: "Statue"}
      }

      expect(response).to redirect_to(edit_product_path(product))

      follow_redirect!

      expect_inertia.to render_component("Products/Edit")
      expect(inertia.props[:errors]).to be_present
    end

    it "updates store_info tags" do
      shopify_info = product.store_infos.shopify.first

      patch product_path(product), params: {
        product: {title: product.title, franchise_id: product.franchise_id, shape: product.shape},
        store_infos: {"0" => {id: shopify_info.id, tag_list: "shopify-tag"}}
      }

      expect(response).to redirect_to(product_path(product))
      expect(shopify_info.reload.tag_list).to eq(["shopify-tag"])
    end

    it "updates multiple store_infos tags simultaneously" do
      shopify_info = product.store_infos.shopify.first
      woo_info = product.store_infos.woo.first

      patch product_path(product), params: {
        product: {title: product.title, franchise_id: product.franchise_id, shape: product.shape},
        store_infos: {
          "0" => {id: shopify_info.id, tag_list: "shopify-tag"},
          "1" => {id: woo_info.id, tag_list: "woo-tag"}
        }
      }

      expect(shopify_info.reload.tag_list).to eq(["shopify-tag"])
      expect(woo_info.reload.tag_list).to eq(["woo-tag"])
    end

    it "adds a new store_info to a product that has none" do
      product_no_stores = create(:product)
      product_no_stores.store_infos.destroy_all

      patch product_path(product_no_stores), params: {
        product: {title: product_no_stores.title, franchise_id: product_no_stores.franchise_id, shape: product_no_stores.shape},
        store_infos: {"0" => {store_name: "shopify", tag_list: "new-store"}}
      }

      product_no_stores.reload
      expect(product_no_stores.store_infos.shopify.count).to eq(1)
      expect(product_no_stores.store_infos.shopify.first.tag_list).to eq(["new-store"])
    end

    it "redirects with duplicate store_name error" do
      patch product_path(product), params: {
        product: {title: product.title, franchise_id: product.franchise_id, shape: product.shape},
        store_infos: {"0" => {store_name: "shopify", tag_list: "duplicate"}}
      }

      expect(response).to redirect_to(edit_product_path(product))
      expect(product.store_infos.shopify.count).to eq(1)
    end

    it "does not affect store_infos when no store_infos params provided" do
      original_count = product.store_infos.count

      patch product_path(product), params: {
        product: {title: "New Title", franchise_id: product.franchise_id, shape: product.shape}
      }

      product.reload
      expect(product.title).to eq("New Title")
      expect(product.store_infos.count).to eq(original_count)
    end

    it "updates variant SKU" do
      variant = product.variants.first

      patch product_path(product), params: {
        product: {title: product.title, franchise_id: product.franchise_id, shape: product.shape},
        variants: {"0" => {id: variant.id, sku: "NEW-SKU-123"}}
      }

      expect(variant.reload.sku).to eq("NEW-SKU-123")
    end

    it "updates product editing with nested variants and store infos in the submitted form shape" do
      variant = product.variants.first
      shopify_info = product.store_infos.shopify.first

      patch product_path(product), params: {
        product: {
          title: "Updated Title",
          franchise_id: product.franchise_id,
          shape: product.shape,
          description: "<p>Updated body</p>",
          brand_ids: product.brand_ids
        },
        variants: {
          "0" => {
            id: variant.id,
            sku: "UPDATED-SKU",
            size_id: variant.size_id,
            version_id: variant.version_id,
            color_id: variant.color_id,
            purchase_cost: variant.purchase_cost,
            selling_price: variant.selling_price,
            weight: variant.weight,
            _destroy: "0"
          }
        },
        store_infos: {
          "0" => {
            id: shopify_info.id,
            store_name: shopify_info.store_name,
            tag_list: "refreshed-tag",
            _destroy: "0"
          }
        }
      }

      expect(response).to redirect_to(product_path(product.reload))
      expect(variant.reload.sku).to eq("UPDATED-SKU")
      expect(shopify_info.reload.tag_list).to eq(["refreshed-tag"])
      expect(product.reload.description.body.to_html).to include("Updated body")
    end

    it "persists tags through product updates that omit store_infos" do
      shopify_info = product.store_infos.shopify.first
      shopify_info.update(tag_list: "original, tags")

      patch product_path(product), params: {
        product: {title: "Just Title Update", franchise_id: product.franchise_id, shape: product.shape}
      }

      expect(shopify_info.reload.tag_list).to match_array(["original", "tags"])
    end
  end

  describe "POST /products — base variant" do
    let(:franchise) { create(:franchise) }

    it "creates a base variant automatically when no variants are submitted" do
      post products_path, params: {
        product: {title: "No Variants Product", franchise_id: franchise.id, shape: "Statue"}
      }

      created = Product.find_by!(title: "No Variants Product")
      expect(created.base_variant).to be_present
      expect(created.base_variant.size_id).to be_nil
      expect(created.base_variant.version_id).to be_nil
      expect(created.base_variant.color_id).to be_nil
    end

    it "creates a base variant even when a blank variant form is removed before submit" do
      post products_path, params: {
        product: {title: "Removed Blank Variant", franchise_id: franchise.id, shape: "Statue"},
        variants: {}
      }

      created = Product.find_by!(title: "Removed Blank Variant")
      expect(created.base_variant).to be_present
    end
  end

  describe "PATCH /products/:id — variant lifecycle" do
    let(:product) { create(:product) }

    it "hard destroys a variant without sales when _destroy is true" do
      variant = product.variants.find { |v| v.base_model? }
      variant_id = variant.id

      expect {
        patch product_path(product), params: {
          product: {title: product.title, franchise_id: product.franchise_id, shape: product.shape},
          variants: {"0" => {id: variant.id, _destroy: true}}
        }
      }.to change(Variant, :count).by(-1)

      expect(Variant.exists?(variant_id)).to be false
    end

    it "deactivates a variant with sales when _destroy is true" do
      variant = product.variants.find { |v| v.base_model? }
      sale = create(:sale)
      SaleItem.create!(product:, variant:, sale:, qty: 1)

      patch product_path(product), params: {
        product: {title: product.title, franchise_id: product.franchise_id, shape: product.shape},
        variants: {"0" => {id: variant.id, _destroy: true}}
      }

      expect(variant.reload.deactivated_at).to be_present
      expect(Variant.exists?(variant.id)).to be true
    end
  end

  describe "DELETE /products/:id" do
    it "destroys the product and redirects to index" do
      product = create(:product)

      expect {
        delete product_path(product)
      }.to change(Product, :count).by(-1)

      expect(response).to redirect_to(products_path)
    end
  end

  describe "ActionText description" do
    let(:franchise) { create(:franchise) }

    it "stores HTML content in the description" do
      html = "<p>This is a <strong>premium</strong> collectible.</p>"
      product = create(:product, franchise:, description: html)

      expect(product.description.body.to_html.strip).to eq(html)
    end

    it "allows updating description with HTML via the controller" do
      product = create(:product, franchise:)
      html = "<p>Updated <em>description</em>.</p>"

      patch product_path(product), params: {
        product: {
          title: product.title,
          franchise_id: product.franchise_id,
          shape: product.shape,
          description: html
        }
      }

      expect(product.reload.description.body.to_html.strip).to eq(html)
    end
  end
end
