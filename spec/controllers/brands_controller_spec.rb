require "rails_helper"

describe BrandsController do
  before { sign_in_as_admin }
  after { log_out }

  describe "GET #show" do
    let!(:brand) { create(:brand) }
    let!(:products) { create_list(:product, 5, brands: [brand]) }

    it "preloads products to avoid N+1 queries" do
      # Use query count tracking to ensure we don't have N+1 queries
      expect { get :show, params: {id: brand.id} }
        .to make_database_queries(count: 2) # 1 query for brand with includes, 1 minimal query
    end

    it "returns successful response" do
      get :show, params: {id: brand.id}
      expect(response).to be_successful
      expect(assigns[:brand]).to eq(brand)
      expect(assigns[:brand].products.loaded?).to be true
    end
  end

  describe "GET #index" do
    let!(:brands) { create_list(:brand, 3) }

    it "does not need to include products for index view" do
      expect { get :index }
        .to make_database_queries(count: 1) # Single query for brands
    end

    it "returns successful response" do
      get :index
      expect(response).to be_successful
      expect(assigns[:brands]).to match_array(brands)
    end
  end
end
