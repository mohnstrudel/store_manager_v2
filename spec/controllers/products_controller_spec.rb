# frozen_string_literal: true

require "rails_helper"

RSpec.describe ProductsController do
  before { sign_in_as_admin }
  after { log_out }

  describe "GET #show" do
    let(:product) { create(:product) }
    let(:media) { create_list(:media, 2, :for_product, mediaable: product) }

    it "renders the Inertia show component with product media" do
      media
      get :show, params: {id: product.to_param}

      aggregate_failures do
        expect(response).to have_http_status(:ok)
        expect_inertia.to render_component("Products/Show")
        expect(inertia.props[:product][:media].map { |item| item[:id] }).to match_array(
          media.map(&:id)
        )
        expect(inertia.props[:product][:media].map { |item| item[:alt] }).to match_array(
          media.map(&:alt)
        )
      end
    end
  end

  describe "PATCH #update" do
    let(:product) { create(:product, title: "Original Title") }

    it "redirects back with errors after a failed update" do
      patch :update, params: {
        id: product.to_param,
        product: {
          title: "",
          franchise_id: product.franchise_id,
          shape: product.shape
        }
      }

      expect(response).to redirect_to(edit_product_path(product))

      get :edit, params: {id: product.to_param}

      aggregate_failures do
        expect(response).to have_http_status(:ok)
        expect_inertia.to render_component("Products/Edit")
        expect(inertia.props[:errors]).to be_present
        expect(inertia.props[:errors][:title]).to include("can't be blank")
      end
    end
  end

  describe "POST #create" do
    let(:franchise) { create(:franchise) }
    let(:supplier) { create(:supplier) }
    let(:warehouse) { create(:warehouse, is_default: true) }

    it "creates a purchase alongside the product" do
      post :create, params: {
        product: {
          title: "New Product",
          franchise_id: franchise.id,
          shape: Product.default_shape
        },
        variants: {
          "0" => {
            sku: "new-product-with-purchase"
          }
        },
        purchase: {
          supplier_id: supplier.id,
          amount: "2",
          item_price: "15",
          payment_value: "30",
          warehouse_id: warehouse.id
        }
      }

      product = Variant.find_by!(sku: "new-product-with-purchase").product
      purchase = product.purchases.last

      aggregate_failures do
        expect(response).to redirect_to(product)
        expect(flash[:notice]).to eq("Product was successfully created")
        expect(purchase).to be_present
        expect(purchase.supplier).to eq(supplier)
        expect(purchase.purchase_items.count).to eq(2)
        expect(purchase.purchase_items.pluck(:warehouse_id).uniq).to eq([warehouse.id])
        expect(purchase.payments.pluck(:value)).to eq([BigDecimal(30)])
      end
    end

    it "redirects to new with errors when creation fails" do
      post :create, params: {
        product: {
          title: "Broken Purchase Product",
          franchise_id: franchise.id,
          shape: Product.default_shape
        },
        purchase: {
          amount: "2",
          item_price: "15",
          payment_value: "30",
          warehouse_id: warehouse.id
        }
      }

      aggregate_failures do
        expect(response).to redirect_to(new_product_path)

        get :new

        expect(response).to have_http_status(:ok)
        expect_inertia.to render_component("Products/New")
        expect(inertia.props[:errors]).to be_present
        expect(inertia.props[:errors][:initial_purchase]).to include("is invalid")
      end
    end
  end
end
