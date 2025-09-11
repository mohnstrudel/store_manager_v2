require "rails_helper"

RSpec.describe SaleFinder do
  let(:customer) { create(:customer, email: "test@example.com") }
  let(:active_status) { Sale.active_status_names.first }
  let(:completed_status) { Sale.completed_status_names.first }
  let(:order_identifier) { "12345" }
  let(:shopify_order_identifier) { "HSCM#12345" }
  let(:woo_order_identifier) { "12345" }

  describe ".find" do
    context "when order_identifier is blank" do
      it "raises ArgumentError" do
        expect { described_class.find("") }.to raise_error(ArgumentError, "order_identifier cannot be blank")
      end
    end

    context "when only Shopify sale exists" do
      let!(:shopify_sale) { create(:sale, shopify_name: shopify_order_identifier) }

      it "returns the Shopify sale" do
        result = described_class.find(order_identifier)
        expect(result).to eq(shopify_sale)
      end

      it "works when order_identifier already includes HSCM#" do
        result = described_class.find(shopify_order_identifier)
        expect(result).to eq(shopify_sale)
      end
    end

    context "when only Woo sale exists" do
      let!(:woo_sale) { create(:sale, woo_id: woo_order_identifier) }

      it "returns the Woo sale" do
        result = described_class.find(order_identifier)
        expect(result).to eq(woo_sale)
      end
    end

    context "when both Shopify and Woo sales exist" do
      let!(:shopify_sale) { create(:sale, shopify_name: shopify_order_identifier, status: active_status, shopify_created_at: 2.days.ago) }
      let!(:woo_sale) { create(:sale, woo_id: woo_order_identifier, status: active_status, woo_created_at: 1.day.ago) }

      context "when no customer is provided" do
        it "returns the newer active sale" do
          result = described_class.find(order_identifier)
          expect(result).to eq(woo_sale)
        end

        context "when only one sale is active" do
          before do
            woo_sale.update!(status: completed_status)
          end

          it "returns the active sale" do
            result = described_class.find(order_identifier)
            expect(result).to eq(shopify_sale)
          end
        end

        context "when neither sale is active" do
          before do
            shopify_sale.update!(status: completed_status)
            woo_sale.update!(status: completed_status)
          end

          it "returns the newer sale" do
            result = described_class.find(order_identifier)
            expect(result).to eq(woo_sale)
          end
        end
      end

      context "when customer is provided" do
        context "when customer owns both sales" do
          before do
            customer.sales << [shopify_sale, woo_sale]
          end

          it "returns the newer active sale" do
            result = described_class.find(order_identifier, customer.id)
            expect(result).to eq(woo_sale)
          end

          context "when only one sale is active" do
            before do
              woo_sale.update!(status: completed_status)
            end

            it "returns the active sale" do
              result = described_class.find(order_identifier, customer.id)
              expect(result).to eq(shopify_sale)
            end
          end

          context "when neither sale is active" do
            before do
              shopify_sale.update!(status: completed_status)
              woo_sale.update!(status: completed_status)
            end

            it "returns the newer sale" do
              result = described_class.find(order_identifier, customer.id)
              expect(result).to eq(woo_sale)
            end
          end
        end

        context "when customer owns only one sale" do
          before do
            customer.sales << shopify_sale
          end

          it "returns the sale owned by the customer" do
            result = described_class.find(order_identifier, customer.id)
            expect(result).to eq(shopify_sale)
          end
        end

        context "when customer owns neither sale" do
          it "returns the newer active sale" do
            result = described_class.find(order_identifier, customer.id)
            expect(result).to eq(woo_sale)
          end
        end

        context "when customer is identified by email" do
          before do
            customer.sales << shopify_sale
          end

          it "returns the sale owned by the customer" do
            result = described_class.find(order_identifier, customer.email)
            expect(result).to eq(shopify_sale)
          end
        end
      end
    end

    context "when neither Shopify nor Woo sale exists" do
      it "returns nil" do
        result = described_class.find("nonexistent")
        expect(result).to be_nil
      end
    end
  end

  describe "#initialize" do
    it "raises ArgumentError when order_identifier is blank" do
      expect { described_class.new("") }.to raise_error(ArgumentError, "order_identifier cannot be blank")
    end

    it "initializes with valid order_identifier" do
      expect { described_class.new(order_identifier) }.not_to raise_error
    end

    it "accepts customer_identifier as optional parameter" do
      expect { described_class.new(order_identifier, customer.id) }.not_to raise_error
    end
  end

  describe "#find" do
    let(:finder) { described_class.new(order_identifier, customer_identifier) }

    context "when only Shopify sale exists" do
      let!(:shopify_sale) { create(:sale, shopify_name: shopify_order_identifier) }
      let(:customer_identifier) { nil }

      it "returns the Shopify sale" do
        result = finder.find
        expect(result).to eq(shopify_sale)
      end
    end

    context "when both Shopify and Woo sales exist with customer" do
      let!(:shopify_sale) { create(:sale, shopify_name: shopify_order_identifier, status: active_status, shopify_created_at: 2.days.ago) }
      let!(:woo_sale) { create(:sale, woo_id: woo_order_identifier, status: active_status, woo_created_at: 1.day.ago) }
      let(:customer_identifier) { customer.id }

      before do
        customer.sales << [shopify_sale, woo_sale]
      end

      it "returns the newer active sale" do
        result = finder.find
        expect(result).to eq(woo_sale)
      end
    end
  end
end
