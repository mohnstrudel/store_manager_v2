# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Products API" do
  let(:franchise) { create(:franchise) }
  let(:shape) { create(:shape) }
  let(:brand) { create(:brand) }

  before do
    sign_in_as_admin
  end

  describe "description field" do
    it "stores HTML content in the database" do
      html_description = "<p>This is a <strong>premium</strong> collectible figure.</p>"
      product = create(:product, franchise:, shape:, description: html_description)

      expect(product.description.body.to_html.strip).to eq(html_description)
    end

    it "allows updating description with HTML" do
      product = create(:product, franchise:, shape:)
      html_description = "<p>Updated <em>description</em> with formatting.</p>"

      product.update(description: html_description)

      expect(product.reload.description.body.to_html.strip).to eq(html_description)
    end

    it "allows products without descriptions" do
      product = create(:product, franchise:, shape:, description: nil)

      expect(product.description.body).to be_blank
    end
  end

  describe "PATCH/PUT /products/:id with store_infos" do
    let(:product) { create(:product) }

    context "when updating existing store_infos" do
      it "updates store_info tags" do
        # Setup
        shopify_info = product.store_infos.shopify.first
        update_params = {
          title: "Updated Product",
          franchise_id: product.franchise_id,
          shape_id: product.shape_id
        }
        store_infos_params = {
          "0" => {
            id: shopify_info.id,
            tag_list: "shopify-tag"
          }
        }

        # Exercise
        patch product_path(product), params: {product: update_params, store_infos: store_infos_params}

        # Verification
        shopify_info.reload
        expect(shopify_info.tag_list).to eq(["shopify-tag"])
      end

      it "updates multiple store_infos tags simultaneously" do
        # Setup
        shopify_info = product.store_infos.shopify.first
        woo_info = product.store_infos.woo.first
        update_params = {
          title: "Updated Product",
          franchise_id: product.franchise_id,
          shape_id: product.shape_id
        }
        store_infos_params = {
          "0" => {
            id: shopify_info.id,
            tag_list: "shopify-tag"
          },
          "1" => {
            id: woo_info.id,
            tag_list: "woo-tag"
          }
        }

        # Exercise
        patch product_path(product), params: {product: update_params, store_infos: store_infos_params}

        # Verification
        shopify_info.reload
        woo_info.reload
        expect(shopify_info.tag_list).to eq(["shopify-tag"])
        expect(woo_info.tag_list).to eq(["woo-tag"])
      end
    end

    context "when adding new store_infos to existing product" do
      it "adds new store_info to product without existing ones" do
        # Setup
        product_without_stores = create(:product)
        product_without_stores.store_infos.destroy_all
        update_params = {
          title: "Updated Product",
          franchise_id: product_without_stores.franchise_id,
          shape_id: product_without_stores.shape_id
        }
        store_infos_params = {
          "0" => {
            store_name: "shopify",
            tag_list: "new-store"
          }
        }

        # Exercise
        patch product_path(product_without_stores), params: {product: update_params, store_infos: store_infos_params}

        # Verification
        product_without_stores.reload
        expect(product_without_stores.store_infos.shopify.count).to eq(1)
        expect(product_without_stores.store_infos.shopify.first.tag_list).to eq(["new-store"])
      end

      it "does not add duplicate store_name" do
        # Setup - product already has shopify store_info from factory
        update_params = {
          title: "Updated Product",
          franchise_id: product.franchise_id,
          shape_id: product.shape_id
        }
        store_infos_params = {
          "0" => {
            store_name: "shopify",
            tag_list: "duplicate-shopify"
          }
        }

        # Exercise
        patch product_path(product), params: {product: update_params, store_infos: store_infos_params}

        # Verification
        expect(response).to have_http_status(:unprocessable_content)
        product.reload
        expect(product.store_infos.shopify.count).to eq(1)
      end
    end

    context "when updating product without store_infos params" do
      it "updates product without affecting existing store_infos" do
        # Setup
        original_shopify_count = product.store_infos.shopify.count
        original_woo_count = product.store_infos.woo.count
        update_params = {
          title: "Updated Title",
          franchise_id: product.franchise_id,
          shape_id: product.shape_id
        }

        # Exercise
        patch product_path(product), params: {product: update_params}

        # Verification
        product.reload
        expect(product.title).to eq("Updated Title")
        expect(product.store_infos.shopify.count).to eq(original_shopify_count)
        expect(product.store_infos.woo.count).to eq(original_woo_count)
      end
    end

    context "when updating with empty store_infos" do
      it "does not create or modify store_infos" do
        # Setup
        product_without_stores = create(:product)
        product_without_stores.store_infos.destroy_all
        update_params = {
          title: "Updated Product",
          franchise_id: product_without_stores.franchise_id,
          shape_id: product_without_stores.shape_id
        }

        # Exercise
        patch product_path(product_without_stores), params: {product: update_params, store_infos: {}}

        # Verification
        product_without_stores.reload
        expect(product_without_stores.store_infos.count).to eq(0)
      end
    end
  end

  describe "GET /products/:id includes store_infos" do
    it "preloads store_infos with tags" do
      # Setup
      product = create(:product)
      shopify_info = product.store_infos.shopify.first
      shopify_info.update(tag_list: "featured, new")

      # Exercise
      get product_path(product)

      # Verification
      expect(response).to be_successful
      expect(assigns(:product)).to eq(product)
      expect(assigns(:product).store_infos).to be_loaded
      expect(assigns(:product).store_infos.first.tags).to be_loaded
    end
  end

  describe "GET /products/:id" do
    it "renders the product show page sections for sales and purchases" do
      product = create(:product)
      edition = create(:edition, product:)
      active_sale = create(:sale, status: "processing")
      completed_sale = create(:sale, status: "completed")

      create(:sale_item, product:, edition:, sale: active_sale, qty: 1)
      create(:sale_item, product:, edition:, sale: completed_sale, qty: 2)
      create(:purchase, product:, edition:, amount: 3, item_price: 12.5)

      get product_path(product)

      aggregate_failures do
        expect(response).to be_successful
        expect(response.body).to include("Active Sales")
        expect(response.body).to include("Completed Sales")
        expect(response.body).to include("Purchases")
      end
    end
  end

  describe "tags on store_infos" do
    let(:product) { create(:product) }

    it "creates store_info with comma-separated tags" do
      # Setup
      shopify_info = product.store_infos.shopify.first
      update_params = {
        title: "Updated Product",
        franchise_id: product.franchise_id,
        shape_id: product.shape_id
      }
      store_infos_params = {
        "0" => {
          id: shopify_info.id,
          tag_list: "rare, limited, exclusive"
        }
      }

      # Exercise
      patch product_path(product), params: {product: update_params, store_infos: store_infos_params}

      # Verification
      shopify_info.reload
      expect(shopify_info.tag_list).to eq(["rare", "limited", "exclusive"])
      expect(shopify_info.tags.count).to eq(3)
    end

    it "creates store_info with single tag" do
      # Setup
      product_without_stores = create(:product)
      product_without_stores.store_infos.destroy_all
      update_params = {
        title: "Updated Product",
        franchise_id: product_without_stores.franchise_id,
        shape_id: product_without_stores.shape_id
      }
      store_infos_params = {
        "0" => {
          store_name: "shopify",
          tag_list: "featured"
        }
      }

      # Exercise
      patch product_path(product_without_stores), params: {product: update_params, store_infos: store_infos_params}

      # Verification
      product_without_stores.reload
      shopify_info = product_without_stores.store_infos.shopify.first
      expect(shopify_info.tag_list).to eq(["featured"])
    end

    it "updates tags by replacing existing ones" do
      # Setup
      shopify_info = product.store_infos.shopify.first
      shopify_info.update(tag_list: "old, tags")

      update_params = {
        title: "Updated Product",
        franchise_id: product.franchise_id,
        shape_id: product.shape_id
      }
      store_infos_params = {
        "0" => {
          id: shopify_info.id,
          tag_list: "new, tags"
        }
      }

      # Exercise
      patch product_path(product), params: {product: update_params, store_infos: store_infos_params}

      # Verification
      shopify_info.reload
      expect(shopify_info.tag_list).to contain_exactly("new", "tags")
      expect(shopify_info.tag_list).not_to include("old")
    end

    it "clears tags when empty string is provided" do
      # Setup
      shopify_info = product.store_infos.shopify.first
      shopify_info.update(tag_list: "some, tags")

      update_params = {
        title: "Updated Product",
        franchise_id: product.franchise_id,
        shape_id: product.shape_id
      }
      store_infos_params = {
        "0" => {
          id: shopify_info.id,
          tag_list: ""
        }
      }

      # Exercise
      patch product_path(product), params: {product: update_params, store_infos: store_infos_params}

      # Verification
      shopify_info.reload
      expect(shopify_info.tag_list).to be_empty
    end

    it "persists tags through product updates without touching store_infos" do
      # Setup
      shopify_info = product.store_infos.shopify.first
      original_tags = ["original", "tags"]
      shopify_info.update(tag_list: original_tags)

      update_params = {
        title: "Just Title Update",
        franchise_id: product.franchise_id,
        shape_id: product.shape_id
      }

      # Exercise
      patch product_path(product), params: {product: update_params}

      # Verification
      shopify_info.reload
      expect(shopify_info.tag_list).to match_array(original_tags)
    end
  end

  describe "PATCH/PUT /products/:id with editions" do
    let(:product) { create(:product) }
    let(:color) { create(:color, value: "Red") }

    before do
      product.colors << color
      product.build_new_editions
      product.save
    end

    context "when updating edition SKU" do
      it "updates edition SKU" do
        edition = product.editions.find { |current| current.color_id.present? }
        update_params = {
          title: product.title,
          franchise_id: product.franchise_id,
          shape_id: product.shape_id
        }
        editions_params = {
          "0" => {
            id: edition.id,
            sku: "NEW-SKU-123"
          }
        }

        patch product_path(product), params: {product: update_params, editions: editions_params}

        edition.reload
        expect(edition.sku).to eq("NEW-SKU-123")
      end
    end

    context "when destroying edition without sales or purchases" do
      it "destroys the edition" do
        edition = product.editions.find { |current| current.color_id.present? }
        update_params = {
          title: product.title,
          franchise_id: product.franchise_id,
          shape_id: product.shape_id
        }
        editions_params = {
          "0" => {
            id: edition.id,
            _destroy: "1"
          }
        }

        expect {
          patch product_path(product), params: {product: update_params, editions: editions_params}
        }.to change { product.editions.count }.by(-1)
      end
    end

    context "when destroying edition with sale_items" do
      let(:sale) { create(:sale) }
      let!(:sale_item) { SaleItem.create!(product: product, edition: product.editions.first, sale: sale, qty: 1) }

      it "soft deletes the edition by setting deactivated_at" do
        edition = product.editions.first
        update_params = {
          title: product.title,
          franchise_id: product.franchise_id,
          shape_id: product.shape_id
        }
        editions_params = {
          "0" => {
            id: edition.id,
            _destroy: "1"
          }
        }

        patch product_path(product), params: {product: update_params, editions: editions_params}

        edition.reload
        expect(edition.deactivated_at).to be_present
        expect(Edition.exists?(edition.id)).to be true
      end
    end
  end
end
