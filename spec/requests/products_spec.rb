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

  describe "POST /products with store_infos" do
    context "when creating a product with new store_infos" do
      it "creates product with shopify store_info" do
        # Setup
        product_params = {
          title: "Test Product",
          sku: "TEST-001",
          franchise_id: franchise.id,
          shape_id: shape.id,
          store_infos_attributes: {
            "0" => {
              store_name: "shopify",
              tag_list: "new, featured"
            }
          }
        }

        # Exercise
        expect {
          post products_path, params: {product: product_params}
        }.to change(Product, :count).by(1)

        # Verification
        product = Product.last
        expect(product.store_infos.shopify.count).to eq(1)
        shopify_info = product.store_infos.shopify.first
        expect(shopify_info.tag_list).to eq(["new", "featured"])
      end

      it "creates product with woo store_info" do
        # Setup
        product_params = {
          title: "Test Product",
          sku: "TEST-002",
          franchise_id: franchise.id,
          shape_id: shape.id,
          store_infos_attributes: {
            "0" => {
              store_name: "woo",
              tag_list: "woocommerce, exclusive"
            }
          }
        }

        # Exercise
        expect {
          post products_path, params: {product: product_params}
        }.to change(Product, :count).by(1)

        # Verification
        product = Product.last
        expect(product.store_infos.woo.count).to eq(1)
        woo_info = product.store_infos.woo.first
        expect(woo_info.tag_list).to eq(["woocommerce", "exclusive"])
      end

      it "creates product with multiple store_infos" do
        # Setup
        product_params = {
          title: "Test Product",
          sku: "TEST-003",
          franchise_id: franchise.id,
          shape_id: shape.id,
          store_infos_attributes: {
            "0" => {
              store_name: "shopify",
              tag_list: "shopify-tag"
            },
            "1" => {
              store_name: "woo",
              tag_list: "woo-tag"
            }
          }
        }

        # Exercise
        expect {
          post products_path, params: {product: product_params}
        }.to change(Product, :count).by(1)

        # Verification
        product = Product.last
        expect(product.store_infos.count).to eq(2)
        expect(product.store_infos.shopify.count).to eq(1)
        expect(product.store_infos.woo.count).to eq(1)
      end

      it "creates product without store_infos" do
        # Setup
        product_params = {
          title: "Test Product",
          sku: "TEST-004",
          franchise_id: franchise.id,
          shape_id: shape.id
        }

        # Exercise
        expect {
          post products_path, params: {product: product_params}
        }.to change(Product, :count).by(1)

        # Verification
        product = Product.last
        expect(product.store_infos.count).to eq(0)
      end
    end

    context "when store_infos params are invalid" do
      it "does not create product when duplicate store_name is submitted" do
        # Setup
        product_params = {
          title: "Test Product",
          sku: "TEST-005",
          franchise_id: franchise.id,
          shape_id: shape.id,
          store_infos_attributes: {
            "0" => {
              store_name: "shopify",
              tag_list: "tag1"
            },
            "1" => {
              store_name: "shopify",
              tag_list: "tag2"
            }
          }
        }

        # Exercise
        post products_path, params: {product: product_params}

        # Verification
        expect(response).to have_http_status(:unprocessable_content)
        expect(Product.count).to eq(0)
      end
    end
  end

  describe "PATCH/PUT /products/:id with store_infos" do
    let(:product) { create(:product) }

    context "when updating existing store_infos" do
      it "updates store_info store_id and slug" do
        # Setup
        shopify_info = product.store_infos.shopify.first
        update_params = {
          title: "Updated Product",
          sku: product.sku,
          franchise_id: product.franchise_id,
          shape_id: product.shape_id,
          store_infos_attributes: {
            "0" => {
              id: shopify_info.id,
              store_id: "gid://shopify/Product/99999",
              slug: "updated-slug",
              tag_list: "updated"
            }
          }
        }

        # Exercise
        patch product_path(product), params: {product: update_params}

        # Verification
        shopify_info.reload
        expect(shopify_info.store_id).to eq("gid://shopify/Product/99999")
        expect(shopify_info.slug).to eq("updated-slug")
        expect(shopify_info.tag_list).to eq(["updated"])
      end

      it "updates store_info tags" do
        # Setup
        woo_info = product.store_infos.woo.first
        update_params = {
          title: "Updated Product",
          sku: product.sku,
          franchise_id: product.franchise_id,
          shape_id: product.shape_id,
          store_infos_attributes: {
            "0" => {
              id: woo_info.id,
              store_id: woo_info.store_id,
              slug: woo_info.slug,
              tag_list: "tag1, tag2, tag3"
            }
          }
        }

        # Exercise
        patch product_path(product), params: {product: update_params}

        # Verification
        woo_info.reload
        expect(woo_info.tag_list).to eq(["tag1", "tag2", "tag3"])
      end

      it "updates multiple store_infos simultaneously" do
        # Setup
        shopify_info = product.store_infos.shopify.first
        woo_info = product.store_infos.woo.first
        update_params = {
          title: "Updated Product",
          sku: product.sku,
          franchise_id: product.franchise_id,
          shape_id: product.shape_id,
          store_infos_attributes: {
            "0" => {
              id: shopify_info.id,
              store_id: "gid://shopify/Product/11111",
              slug: "shopify-updated",
              tag_list: "shopify-tag"
            },
            "1" => {
              id: woo_info.id,
              store_id: "woo-123",
              slug: "woo-updated",
              tag_list: "woo-tag"
            }
          }
        }

        # Exercise
        patch product_path(product), params: {product: update_params}

        # Verification
        shopify_info.reload
        woo_info.reload
        expect(shopify_info.store_id).to eq("gid://shopify/Product/11111")
        expect(shopify_info.slug).to eq("shopify-updated")
        expect(woo_info.store_id).to eq("woo-123")
        expect(woo_info.slug).to eq("woo-updated")
      end
    end

    context "when adding new store_infos to existing product" do
      it "adds new store_info to product without existing ones" do
        # Setup
        product_without_stores = create(:product)
        product_without_stores.store_infos.destroy_all
        update_params = {
          title: "Updated Product",
          sku: product_without_stores.sku,
          franchise_id: product_without_stores.franchise_id,
          shape_id: product_without_stores.shape_id,
          store_infos_attributes: {
            "0" => {
              store_name: "shopify",
              tag_list: "new-store"
            }
          }
        }

        # Exercise
        patch product_path(product_without_stores), params: {product: update_params}

        # Verification
        product_without_stores.reload
        expect(product_without_stores.store_infos.shopify.count).to eq(1)
        expect(product_without_stores.store_infos.shopify.first.tag_list).to eq(["new-store"])
      end

      it "does not add duplicate store_name" do
        # Setup - product already has shopify store_info from factory
        update_params = {
          title: "Updated Product",
          sku: product.sku,
          franchise_id: product.franchise_id,
          shape_id: product.shape_id,
          store_infos_attributes: {
            "0" => {
              store_name: "shopify",
              tag_list: "duplicate-shopify"
            }
          }
        }

        # Exercise
        patch product_path(product), params: {product: update_params}

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
          sku: product.sku,
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

    context "when updating with empty store_infos_attributes" do
      it "does not create or modify store_infos" do
        # Setup
        product_without_stores = create(:product)
        product_without_stores.store_infos.destroy_all
        update_params = {
          title: "Updated Product",
          sku: product_without_stores.sku,
          franchise_id: product_without_stores.franchise_id,
          shape_id: product_without_stores.shape_id,
          store_infos_attributes: {}
        }

        # Exercise
        patch product_path(product_without_stores), params: {product: update_params}

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

  describe "tags on store_infos" do
    let(:product) { create(:product) }

    it "creates store_info with comma-separated tags" do
      # Setup
      shopify_info = product.store_infos.shopify.first
      update_params = {
        title: "Updated Product",
        sku: product.sku,
        franchise_id: product.franchise_id,
        shape_id: product.shape_id,
        store_infos_attributes: {
          "0" => {
            id: shopify_info.id,
            store_id: shopify_info.store_id,
            slug: shopify_info.slug,
            tag_list: "rare, limited, exclusive"
          }
        }
      }

      # Exercise
      patch product_path(product), params: {product: update_params}

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
        sku: product_without_stores.sku,
        franchise_id: product_without_stores.franchise_id,
        shape_id: product_without_stores.shape_id,
        store_infos_attributes: {
          "0" => {
            store_name: "shopify",
            tag_list: "featured"
          }
        }
      }

      # Exercise
      patch product_path(product_without_stores), params: {product: update_params}

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
        sku: product.sku,
        franchise_id: product.franchise_id,
        shape_id: product.shape_id,
        store_infos_attributes: {
          "0" => {
            id: shopify_info.id,
            store_id: shopify_info.store_id,
            slug: shopify_info.slug,
            tag_list: "new, tags"
          }
        }
      }

      # Exercise
      patch product_path(product), params: {product: update_params}

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
        sku: product.sku,
        franchise_id: product.franchise_id,
        shape_id: product.shape_id,
        store_infos_attributes: {
          "0" => {
            id: shopify_info.id,
            store_id: shopify_info.store_id,
            slug: shopify_info.slug,
            tag_list: ""
          }
        }
      }

      # Exercise
      patch product_path(product), params: {product: update_params}

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
        sku: product.sku,
        franchise_id: product.franchise_id,
        shape_id: product.shape_id
      }

      # Exercise
      patch product_path(product), params: {product: update_params}

      # Verification
      shopify_info.reload
      expect(shopify_info.tag_list).to eq(original_tags)
    end
  end
end
