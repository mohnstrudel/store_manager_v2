# frozen_string_literal: true

require "rails_helper"

RSpec.describe ProductsController do
  render_views

  before { sign_in_as_admin }
  after { log_out }

  describe "GET #show" do
    let(:product) { create(:product) }
    let(:media) { create_list(:media, 2, :for_product, mediaable: product) }

    it "renders the shared gallery for product media" do
      media
      get :show, params: {id: product.to_param}

      aggregate_failures do
        expect(response).to have_http_status(:ok)
        expect(response.body).to include('data-controller="gallery"')
        expect(response.body).to include('data-gallery-target="main"')
        expect(response.body).to include('data-gallery-target="slide"')
      end
    end
  end

  describe "PATCH #update" do
    let(:product) { create(:product, title: "Original Title") }

    it "keeps submitted attributes after a failed update" do # rubocop:disable RSpec/MultipleExpectations
      patch :update, params: {
        id: product.to_param,
        product: {
          title: "",
          franchise_id: product.franchise_id,
          shape_id: product.shape_id
        }
      }

      expect(response).to have_http_status(:unprocessable_content)
      expect(response).to render_template(:edit)
      expect(assigns(:product).title).to eq("")
      expect(assigns(:product).errors[:title]).to include("can't be blank")
    end
  end

  describe "POST #create" do
    let(:franchise) { create(:franchise) }
    let(:shape) { create(:shape) }
    let(:supplier) { create(:supplier) }
    let(:warehouse) { create(:warehouse, is_default: true) }

    it "creates a purchase alongside the product" do
      post :create, params: {
        product: {
          title: "New Product",
          franchise_id: franchise.id,
          shape_id: shape.id
        },
        editions: {
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

      product = Edition.find_by!(sku: "new-product-with-purchase").product
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

    it "rebuilds the submitted purchase when creation fails" do
      post :create, params: {
        product: {
          title: "Broken Purchase Product",
          franchise_id: franchise.id,
          shape_id: shape.id
        },
        purchase: {
          amount: "2",
          item_price: "15",
          payment_value: "30",
          warehouse_id: warehouse.id
        }
      }

      aggregate_failures do
        expect(response).to have_http_status(:unprocessable_content)
        expect(response).to render_template(:new)
        expect(assigns(:product).errors[:initial_purchase]).to include("is invalid")
        expect(assigns(:purchase)).to be_present
        expect(assigns(:purchase).amount).to eq(2)
        expect(assigns(:purchase).item_price).to eq(BigDecimal(15))
        expect(assigns(:purchase).payment_value).to eq(BigDecimal(30))
        expect(assigns(:purchase).warehouse_id).to eq(warehouse.id)
      end
    end
  end
end
