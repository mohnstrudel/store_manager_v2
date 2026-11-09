# frozen_string_literal: true

require "rails_helper"

RSpec.describe Shopify::Api::Client do
  let(:client) { described_class.new }
  let(:mock_graphql_client) { instance_double(ShopifyAPI::Clients::Graphql::Admin) }

  before do
    allow(ENV).to receive(:fetch).with("SHOPIFY_DOMAIN").and_return("test-shop.myshopify.com")
    allow(ENV).to receive(:fetch).with("SHOPIFY_API_TOKEN").and_return("test-token")
    allow(ShopifyAPI::Clients::Graphql::Admin).to receive(:new).and_return(mock_graphql_client)
  end

  describe "#initialize" do
    it "creates a GraphQL client with Shopify credentials" do
      expect(ShopifyAPI::Clients::Graphql::Admin).to receive(:new).with(
        session: kind_of(ShopifyAPI::Auth::Session)
      )
      described_class.new
    end
  end

  describe "throttling" do
    let(:throttled_response) do
      double(body: {"errors" => [{"message" => "Throttled", "extensions" => {"code" => "THROTTLED"}}]})
    end

    def http_error(code)
      ShopifyAPI::Errors::HttpResponseError.new(
        response: ShopifyAPI::Clients::HttpResponse.new(code:, headers: {}, body: "error")
      )
    end

    queries = {
      "fetch_product" => ->(client) { client.fetch_product("gid://shopify/Product/1") },
      "fetch_products" => ->(client) { client.fetch_products(cursor: nil, batch_size: 10) },
      "fetch_order" => ->(client) { client.fetch_order("gid://shopify/Order/1") },
      "fetch_orders" => ->(client) { client.fetch_orders(cursor: nil, batch_size: 10) }
    }
    mutations = {
      "create_product" => ->(client) { client.create_product("{title: \"Product\"}") },
      "update_product" => ->(client) { client.update_product("gid://shopify/Product/1", {title: "Product"}) },
      "create_product_options" => ->(client) { client.create_product_options("gid://shopify/Product/1", [{name: "Size"}]) },
      "attach_media" => ->(client) { client.attach_media("gid://shopify/Product/1", [{originalSource: "https://example.com/1.jpg"}]) },
      "update_media" => ->(client) { client.update_media([{id: "gid://shopify/MediaImage/1", alt: "Alt"}]) },
      "reorder_media" => ->(client) { client.reorder_media("gid://shopify/Product/1", [{id: "gid://shopify/MediaImage/1", newPosition: 0}]) }
    }

    queries.merge(mutations).each do |name, call|
      describe "##{name}" do
        it "raises Throttled on HTTP 429" do
          allow(mock_graphql_client).to receive(:query).and_raise(http_error(429))

          expect { call.call(client) }.to raise_error(described_class::Throttled)
        end

        it "raises Throttled on a THROTTLED error inside an HTTP 200" do
          allow(mock_graphql_client).to receive(:query).and_return(throttled_response)

          expect { call.call(client) }.to raise_error(described_class::Throttled)
        end

        it "does not turn other HTTP failures into Throttled" do
          error = http_error(500)
          allow(mock_graphql_client).to receive(:query).and_raise(error)

          expect { call.call(client) }.to raise_error(error)
        end
      end
    end

    mutations.each do |name, call|
      it "#{name} sends no Sentry message when throttled" do
        allow(Sentry).to receive(:capture_message)
        allow(mock_graphql_client).to receive(:query).and_return(throttled_response)

        expect { call.call(client) }.to raise_error(described_class::Throttled)

        expect(Sentry).not_to have_received(:capture_message)
      end
    end

    it "keeps other query errors as plain ApiError" do
      allow(mock_graphql_client).to receive(:query).and_return(
        double(body: {"errors" => [{"message" => "Access denied", "extensions" => {"code" => "ACCESS_DENIED"}}]})
      )

      expect { client.fetch_products(cursor: nil, batch_size: 10) }
        .to raise_error(described_class::ApiError, "Failed to fetch products: Access denied") { |error|
          expect(error).not_to be_a(described_class::Throttled)
        }
    end

    it "keeps other mutation errors as plain ApiError and still reports them" do
      allow(Sentry).to receive(:capture_message)
      allow(mock_graphql_client).to receive(:query).and_return(
        double(body: {"errors" => [{"message" => "Access denied", "extensions" => {"code" => "ACCESS_DENIED"}}]})
      )

      expect { client.update_product("gid://shopify/Product/1", {title: "Product"}) }
        .to raise_error(described_class::ApiError) { |error| expect(error).not_to be_a(described_class::Throttled) }

      expect(Sentry).to have_received(:capture_message)
    end

    it "treats Throttled as an ApiError so existing ApiError handling applies" do
      expect(described_class::Throttled.new).to be_a(described_class::ApiError)
    end
  end

  describe "#fetch_product" do
    let(:product_id) { "gid://shopify/Product/123" }
    let(:product_response) do
      double(body: {
        "data" => {
          "product" => {
            "id" => product_id,
            "title" => "Test Product",
            "handle" => "test-product"
          }
        }
      })
    end

    before do
      allow(mock_graphql_client).to receive(:query).and_return(product_response)
    end

    it "raises ArgumentError when product_id is blank" do
      expect { client.fetch_product(nil) }.to raise_error(ArgumentError, "Product Shopify ID (store_id) is required")
      expect { client.fetch_product("") }.to raise_error(ArgumentError, "Product Shopify ID (store_id) is required")
    end

    it "executes the product query with the correct ID" do
      client.fetch_product(product_id)

      expect(mock_graphql_client).to have_received(:query).with(
        query: kind_of(String),
        variables: {id: product_id}
      )
    end

    it "returns the product data" do
      result = client.fetch_product(product_id)
      expect(result).to eq(product_response.body.dig("data", "product"))
    end

    context "when the product's variants fit the requested page" do
      let(:product_response) do
        double(body: {
          "data" => {
            "product" => {
              "id" => product_id,
              "variants" => {"pageInfo" => {"hasNextPage" => false}, "edges" => []}
            }
          }
        })
      end

      it "does not report truncation" do
        allow(Sentry).to receive(:capture_message)

        client.fetch_product(product_id)

        expect(Sentry).not_to have_received(:capture_message)
      end
    end

    context "when the product's variants did not fit the requested page" do
      let(:product_response) do
        double(body: {
          "data" => {
            "product" => {
              "id" => product_id,
              "variants" => {"pageInfo" => {"hasNextPage" => true}, "edges" => []}
            }
          }
        })
      end

      it "reports the truncated product loudly" do
        allow(Sentry).to receive(:capture_message)
        allow(Rails.logger).to receive(:error)

        client.fetch_product(product_id)

        aggregate_failures do
          expect(Sentry).to have_received(:capture_message).with(
            "Shopify variants truncated for 1 product(s): gid://shopify/Product/123",
            level: :error,
            tags: {api: "shopify", operation: "variants"},
            extra: {product_ids: ["gid://shopify/Product/123"]}
          )
          expect(Rails.logger).to have_received(:error).with(
            "Shopify variants truncated for 1 product(s): gid://shopify/Product/123"
          )
        end
      end

      it "still returns the product data" do
        allow(Sentry).to receive(:capture_message)

        expect(client.fetch_product(product_id)).to eq(product_response.body.dig("data", "product"))
      end
    end

    context "when Shopify has no such product" do
      let(:product_response) { double(body: {"data" => {"product" => nil}}) }

      it "returns nil without reporting" do
        allow(Sentry).to receive(:capture_message)

        expect(client.fetch_product(product_id)).to be_nil
        expect(Sentry).not_to have_received(:capture_message)
      end
    end

    context "when Shopify reports the query cost" do
      let(:product_response) do
        double(body: {
          "data" => {"product" => {"id" => product_id}},
          "extensions" => {
            "cost" => {
              "requestedQueryCost" => 62,
              "actualQueryCost" => 9,
              "throttleStatus" => {
                "maximumAvailable" => 2000.0,
                "currentlyAvailable" => 1991.0,
                "restoreRate" => 100.0
              }
            }
          }
        })
      end

      it "logs the measured cost and the remaining budget" do
        allow(Rails.logger).to receive(:info)

        client.fetch_product(product_id)

        expect(Rails.logger).to have_received(:info).with(
          "Shopify product query cost: requested=62 actual=9 " \
          "available=1991.0/2000.0 restore_rate=100.0"
        )
      end
    end

    context "when Shopify API returns errors" do
      let(:error_response) do
        double(body: {
          "errors" => [
            {"message" => "Product not found"},
            {"message" => "Access denied"}
          ]
        })
      end

      before do
        allow(mock_graphql_client).to receive(:query).and_return(error_response)
      end

      it "raises ApiError with resource name and error messages" do
        expect {
          client.fetch_product(product_id)
        }.to raise_error(described_class::ApiError, "Failed to fetch product: Product not found, Access denied")
      end
    end

    context "when Shopify API returns a single error" do
      let(:error_response) do
        double(body: {
          "errors" => [
            {"message" => "Invalid product ID"}
          ]
        })
      end

      before do
        allow(mock_graphql_client).to receive(:query).and_return(error_response)
      end

      it "raises ApiError with single error message" do
        expect {
          client.fetch_product(product_id)
        }.to raise_error(described_class::ApiError, "Failed to fetch product: Invalid product ID")
      end
    end
  end

  describe "#fetch_products" do
    let(:cursor) { "cursor123" }
    let(:batch_size) { 10 }
    let(:products_response) do
      double(body: {
        "data" => {
          "products" => {
            "edges" => [
              {"node" => {"id" => "gid://shopify/Product/1", "title" => "Product 1"}},
              {"node" => {"id" => "gid://shopify/Product/2", "title" => "Product 2"}}
            ],
            "pageInfo" => {
              "hasNextPage" => true,
              "endCursor" => "next_cursor"
            }
          }
        }
      })
    end

    before do
      allow(mock_graphql_client).to receive(:query).and_return(products_response)
    end

    it "executes the products list query with pagination params" do
      client.fetch_products(cursor: cursor, batch_size: batch_size)

      expect(mock_graphql_client).to have_received(:query).with(
        query: kind_of(String),
        variables: {
          first: batch_size,
          after: cursor
        }
      )
    end

    it "asks once for the products updated since the given time, with no separate media query" do
      updated_since = Time.utc(2026, 11, 10, 9, 45)

      client.fetch_products(cursor: cursor, batch_size: batch_size, updated_since:)

      expect(mock_graphql_client).to have_received(:query).once.with(
        query: Shopify::Graphql::ProductQuery.list(updated_since:),
        variables: {first: batch_size, after: cursor}
      )
    end

    it "returns structured response with items and pagination info" do
      result = client.fetch_products(cursor: cursor, batch_size: batch_size)

      expect(result[:items]).to eq([
        {"id" => "gid://shopify/Product/1", "title" => "Product 1"},
        {"id" => "gid://shopify/Product/2", "title" => "Product 2"}
      ])
      expect(result[:has_next_page]).to be(true)
      expect(result[:end_cursor]).to eq("next_cursor")
    end

    context "when every product's variants fit the requested page" do
      let(:products_response) do
        double(body: {
          "data" => {
            "products" => {
              "edges" => [
                {"node" => {
                  "id" => "gid://shopify/Product/1",
                  "variants" => {"pageInfo" => {"hasNextPage" => false}, "edges" => []}
                }}
              ],
              "pageInfo" => {"hasNextPage" => false, "endCursor" => nil}
            }
          }
        })
      end

      it "does not report truncation" do
        allow(Sentry).to receive(:capture_message)

        client.fetch_products(cursor: cursor, batch_size: batch_size)

        expect(Sentry).not_to have_received(:capture_message)
      end
    end

    context "when some products' variants were truncated" do
      let(:products_response) do
        double(body: {
          "data" => {
            "products" => {
              "edges" => [
                {"node" => {
                  "id" => "gid://shopify/Product/1",
                  "variants" => {"pageInfo" => {"hasNextPage" => true}, "edges" => []}
                }},
                {"node" => {
                  "id" => "gid://shopify/Product/2",
                  "variants" => {"pageInfo" => {"hasNextPage" => false}, "edges" => []}
                }},
                {"node" => {
                  "id" => "gid://shopify/Product/3",
                  "variants" => {"pageInfo" => {"hasNextPage" => true}, "edges" => []}
                }}
              ],
              "pageInfo" => {"hasNextPage" => false, "endCursor" => nil}
            }
          }
        })
      end

      it "reports only the truncated products loudly" do
        allow(Sentry).to receive(:capture_message)

        client.fetch_products(cursor: cursor, batch_size: batch_size)

        expect(Sentry).to have_received(:capture_message).with(
          "Shopify variants truncated for 2 product(s): gid://shopify/Product/1, gid://shopify/Product/3",
          level: :error,
          tags: {api: "shopify", operation: "variants"},
          extra: {product_ids: ["gid://shopify/Product/1", "gid://shopify/Product/3"]}
        )
      end

      it "still returns every fetched product" do
        allow(Sentry).to receive(:capture_message)

        result = client.fetch_products(cursor: cursor, batch_size: batch_size)

        expect(result[:items].pluck("id")).to eq([
          "gid://shopify/Product/1",
          "gid://shopify/Product/2",
          "gid://shopify/Product/3"
        ])
      end
    end

    context "when Shopify reports the query cost" do
      let(:products_response) do
        double(body: {
          "data" => {
            "products" => {
              "edges" => [],
              "pageInfo" => {"hasNextPage" => false, "endCursor" => nil}
            }
          },
          "extensions" => {
            "cost" => {
              "requestedQueryCost" => 596,
              "actualQueryCost" => 312,
              "throttleStatus" => {
                "maximumAvailable" => 2000.0,
                "currentlyAvailable" => 1688.0,
                "restoreRate" => 100.0
              }
            }
          }
        })
      end

      it "logs the measured cost and the remaining budget" do
        allow(Rails.logger).to receive(:info)

        client.fetch_products(cursor: cursor, batch_size: batch_size)

        expect(Rails.logger).to have_received(:info).with(
          "Shopify products query cost: requested=596 actual=312 " \
          "available=1688.0/2000.0 restore_rate=100.0"
        )
      end
    end

    context "when Shopify API returns errors" do
      let(:error_response) do
        double(body: {
          "errors" => [
            {"message" => "Authentication error"}
          ]
        })
      end

      before do
        allow(mock_graphql_client).to receive(:query).and_return(error_response)
      end

      it "raises ApiError" do
        expect {
          client.fetch_products(cursor: nil, batch_size: 10)
        }.to raise_error(described_class::ApiError, "Failed to fetch products: Authentication error")
      end
    end
  end

  describe "#fetch_order" do
    let(:order_id) { "gid://shopify/Order/456" }
    let(:order_response) do
      double(body: {
        "data" => {
          "order" => {
            "id" => order_id,
            "name" => "#1001",
            "totalPriceSet" => {
              "shopMoney" => {
                "amount" => "99.99"
              }
            }
          }
        }
      })
    end

    before do
      allow(mock_graphql_client).to receive(:query).and_return(order_response)
    end

    it "raises ArgumentError when order_id is blank" do
      expect { client.fetch_order(nil) }.to raise_error(ArgumentError, "Order ID (sale's store_id) is required")
      expect { client.fetch_order("") }.to raise_error(ArgumentError, "Order ID (sale's store_id) is required")
    end

    it "executes the order query with the correct ID" do
      client.fetch_order(order_id)

      expect(mock_graphql_client).to have_received(:query).with(
        query: kind_of(String),
        variables: {id: order_id}
      )
    end

    it "returns the order data" do
      result = client.fetch_order(order_id)
      expect(result).to eq(order_response.body.dig("data", "order"))
    end

    it "does not report truncation for a complete order" do
      allow(Sentry).to receive(:capture_message)

      client.fetch_order(order_id)

      expect(Sentry).not_to have_received(:capture_message)
    end

    context "when the order's line items did not fit the requested page" do
      let(:order_response) do
        double(body: {
          "data" => {
            "order" => {
              "id" => order_id,
              "lineItems" => {
                "pageInfo" => {"hasNextPage" => true},
                "nodes" => []
              }
            }
          }
        })
      end

      it "reports the truncated order loudly" do
        allow(Sentry).to receive(:capture_message)
        allow(Rails.logger).to receive(:error)

        client.fetch_order(order_id)

        aggregate_failures do
          expect(Sentry).to have_received(:capture_message).with(
            "Shopify line items truncated for 1 order(s): gid://shopify/Order/456",
            level: :error,
            tags: {api: "shopify", operation: "lineItems"},
            extra: {order_ids: ["gid://shopify/Order/456"]}
          )
          expect(Rails.logger).to have_received(:error).with(
            "Shopify line items truncated for 1 order(s): gid://shopify/Order/456"
          )
        end
      end

      it "still returns the order data" do
        allow(Sentry).to receive(:capture_message)

        expect(client.fetch_order(order_id)).to eq(order_response.body.dig("data", "order"))
      end
    end

    context "when Shopify API returns errors" do
      let(:error_response) do
        double(body: {
          "errors" => [
            {"message" => "Order not found"}
          ]
        })
      end

      before do
        allow(mock_graphql_client).to receive(:query).and_return(error_response)
      end

      it "raises ApiError" do
        expect {
          client.fetch_order(order_id)
        }.to raise_error(described_class::ApiError, "Failed to fetch order: Order not found")
      end
    end
  end

  describe "#fetch_orders" do
    let(:cursor) { "cursor456" }
    let(:batch_size) { 10 }
    let(:orders_response) do
      double(body: {
        "data" => {
          "orders" => {
            "edges" => [
              {"node" => {"id" => "gid://shopify/Order/1", "name" => "#1001"}},
              {"node" => {"id" => "gid://shopify/Order/2", "name" => "#1002"}}
            ],
            "pageInfo" => {
              "hasNextPage" => false,
              "endCursor" => nil
            }
          }
        }
      })
    end

    before do
      allow(mock_graphql_client).to receive(:query).and_return(orders_response)
    end

    it "executes the orders list query with pagination params" do
      client.fetch_orders(cursor: cursor, batch_size: batch_size)

      expect(mock_graphql_client).to have_received(:query).with(
        query: kind_of(String),
        variables: {
          first: batch_size,
          after: cursor
        }
      )
    end

    it "asks once for the orders updated since the given time" do
      updated_since = Time.utc(2026, 11, 10, 9, 45)

      client.fetch_orders(cursor: cursor, batch_size: batch_size, updated_since:)

      expect(mock_graphql_client).to have_received(:query).once.with(
        query: Shopify::Graphql::OrderQuery.list(updated_since:),
        variables: {first: batch_size, after: cursor}
      )
    end

    it "returns structured response with items and pagination info" do
      result = client.fetch_orders(cursor: cursor, batch_size: batch_size)

      expect(result[:items]).to eq([
        {"id" => "gid://shopify/Order/1", "name" => "#1001"},
        {"id" => "gid://shopify/Order/2", "name" => "#1002"}
      ])
      expect(result[:has_next_page]).to be(false)
      expect(result[:end_cursor]).to be_nil
    end

    it "logs no cost when Shopify sent no extensions" do
      allow(Rails.logger).to receive(:info)

      client.fetch_orders(cursor: cursor, batch_size: batch_size)

      expect(Rails.logger).not_to have_received(:info)
    end

    context "when Shopify reports the query cost" do
      let(:orders_response) do
        double(body: {
          "data" => {
            "orders" => {
              "edges" => [],
              "pageInfo" => {"hasNextPage" => false, "endCursor" => nil}
            }
          },
          "extensions" => {
            "cost" => {
              "requestedQueryCost" => 862,
              "actualQueryCost" => 431,
              "throttleStatus" => {
                "maximumAvailable" => 2000.0,
                "currentlyAvailable" => 1138.0,
                "restoreRate" => 100.0
              }
            }
          }
        })
      end

      it "logs the measured cost and the remaining budget" do
        allow(Rails.logger).to receive(:info)

        client.fetch_orders(cursor: cursor, batch_size: batch_size)

        expect(Rails.logger).to have_received(:info).with(
          "Shopify orders query cost: requested=862 actual=431 " \
          "available=1138.0/2000.0 restore_rate=100.0"
        )
      end
    end

    context "when some orders' line items were truncated" do
      let(:orders_response) do
        double(body: {
          "data" => {
            "orders" => {
              "edges" => [
                {"node" => {
                  "id" => "gid://shopify/Order/1",
                  "lineItems" => {"pageInfo" => {"hasNextPage" => true}, "nodes" => []}
                }},
                {"node" => {
                  "id" => "gid://shopify/Order/2",
                  "lineItems" => {"pageInfo" => {"hasNextPage" => false}, "nodes" => []}
                }},
                {"node" => {
                  "id" => "gid://shopify/Order/3",
                  "lineItems" => {"pageInfo" => {"hasNextPage" => true}, "nodes" => []}
                }}
              ],
              "pageInfo" => {"hasNextPage" => false, "endCursor" => nil}
            }
          }
        })
      end

      it "reports only the truncated orders loudly" do
        allow(Sentry).to receive(:capture_message)

        client.fetch_orders(cursor: cursor, batch_size: batch_size)

        expect(Sentry).to have_received(:capture_message).with(
          "Shopify line items truncated for 2 order(s): gid://shopify/Order/1, gid://shopify/Order/3",
          level: :error,
          tags: {api: "shopify", operation: "lineItems"},
          extra: {order_ids: ["gid://shopify/Order/1", "gid://shopify/Order/3"]}
        )
      end

      it "still returns every fetched order" do
        allow(Sentry).to receive(:capture_message)

        result = client.fetch_orders(cursor: cursor, batch_size: batch_size)

        expect(result[:items].pluck("id")).to eq([
          "gid://shopify/Order/1",
          "gid://shopify/Order/2",
          "gid://shopify/Order/3"
        ])
      end
    end

    context "when Shopify API returns errors" do
      let(:error_response) do
        double(body: {
          "errors" => [
            {"message" => "Access denied"}
          ]
        })
      end

      before do
        allow(mock_graphql_client).to receive(:query).and_return(error_response)
      end

      it "raises ApiError" do
        expect {
          client.fetch_orders(cursor: nil, batch_size: 10)
        }.to raise_error(described_class::ApiError, "Failed to fetch orders: Access denied")
      end

      it "still logs the throttle status Shopify reported with the error" do
        allow(mock_graphql_client).to receive(:query).and_return(
          double(body: {
            "errors" => [{"message" => "Throttled", "extensions" => {"code" => "THROTTLED"}}],
            "extensions" => {
              "cost" => {
                "requestedQueryCost" => 862,
                "actualQueryCost" => nil,
                "throttleStatus" => {
                  "maximumAvailable" => 2000.0,
                  "currentlyAvailable" => 12.0,
                  "restoreRate" => 100.0
                }
              }
            }
          })
        )
        allow(Rails.logger).to receive(:info)

        expect { client.fetch_orders(cursor: nil, batch_size: 250) }
          .to raise_error(described_class::Throttled)

        expect(Rails.logger).to have_received(:info).with(
          "Shopify orders query cost: requested=862 actual= " \
          "available=12.0/2000.0 restore_rate=100.0"
        )
      end
    end
  end

  describe "#create_product" do
    let(:serialized_product) { '{title: "New Product", productType: "Test"}' }
    let(:create_response) do
      double(body: {
        "data" => {
          "productCreate" => {
            "product" => {
              "id" => "gid://shopify/Product/789",
              "title" => "New Product",
              "handle" => "new-product"
            },
            "userErrors" => []
          }
        }
      })
    end

    before do
      allow(mock_graphql_client).to receive(:query).and_return(create_response)
    end

    it "executes the product create mutation" do
      client.create_product(serialized_product)

      expect(mock_graphql_client).to have_received(:query).with(
        query: kind_of(String),
        variables: {}
      )
    end

    it "returns the created product data" do
      result = client.create_product(serialized_product)
      expect(result).to eq(create_response.body.dig("data", "productCreate", "product"))
    end

    context "when API errors occur" do
      let(:error_response) do
        double(body: {
          "data" => {
            "productCreate" => {
              "product" => nil,
              "userErrors" => []
            }
          },
          "errors" => [
            {"message" => "API rate limit exceeded"}
          ]
        })
      end

      before do
        allow(mock_graphql_client).to receive(:query).and_return(error_response)
        allow(Sentry).to receive(:capture_message)
      end

      it "captures error in Sentry" do
        expect(Sentry).to receive(:capture_message).with(
          "Shopify productCreate failed: API rate limit exceeded",
          level: :error,
          tags: {
            api: "shopify",
            operation: "productCreate"
          },
          extra: hash_including(:query, :shopify_errors)
        )

        expect { client.create_product(serialized_product) }.to raise_error(described_class::ApiError)
      end

      it "raises ApiError with API error message" do
        expect {
          client.create_product(serialized_product)
        }.to raise_error(described_class::ApiError, "Failed to call the productCreate API mutation: API rate limit exceeded")
      end
    end

    context "when user errors occur" do
      let(:error_response) do
        double(body: {
          "data" => {
            "productCreate" => {
              "product" => nil,
              "userErrors" => [
                {"field" => ["title"], "message" => "Title is required"},
                {"field" => ["productType"], "message" => "Product type is invalid"}
              ]
            }
          }
        })
      end

      before do
        allow(mock_graphql_client).to receive(:query).and_return(error_response)
        allow(Sentry).to receive(:capture_message)
      end

      it "captures error in Sentry" do
        expect(Sentry).to receive(:capture_message).with(
          "Shopify productCreate failed: Title is required, Product type is invalid",
          level: :error,
          tags: {
            api: "shopify",
            operation: "productCreate"
          },
          extra: hash_including(:query)
        )

        expect { client.create_product(serialized_product) }.to raise_error(described_class::ApiError)
      end

      it "raises ApiError with user error messages" do
        expect {
          client.create_product(serialized_product)
        }.to raise_error(described_class::ApiError, "Failed to call the productCreate API mutation: Title is required, Product type is invalid")
      end
    end
  end

  describe "#update_product" do
    let(:product_id) { "gid://shopify/Product/123" }
    let(:serialized_product) { {title: "Updated Product"} }
    let(:update_response) do
      double(body: {
        "data" => {
          "productUpdate" => {
            "product" => {
              "id" => product_id,
              "title" => "Updated Product"
            },
            "userErrors" => []
          }
        }
      })
    end

    before do
      allow(mock_graphql_client).to receive(:query).and_return(update_response)
    end

    it "executes the product update mutation" do
      client.update_product(product_id, serialized_product)

      expect(mock_graphql_client).to have_received(:query).with(
        query: kind_of(String),
        variables: {product: serialized_product.merge(id: product_id)}
      )
    end

    it "returns the updated product data" do
      result = client.update_product(product_id, serialized_product)
      expect(result).to eq(update_response.body.dig("data", "productUpdate", "product"))
    end

    context "when Shopify reports the query cost" do
      let(:update_response) do
        double(body: {
          "data" => {"productUpdate" => {"product" => {"id" => product_id}, "userErrors" => []}},
          "extensions" => {
            "cost" => {
              "requestedQueryCost" => 10,
              "actualQueryCost" => 10,
              "throttleStatus" => {
                "maximumAvailable" => 2000.0,
                "currentlyAvailable" => 1990.0,
                "restoreRate" => 100.0
              }
            }
          }
        })
      end

      it "logs the measured cost and the remaining budget" do
        allow(Rails.logger).to receive(:info)

        client.update_product(product_id, serialized_product)

        expect(Rails.logger).to have_received(:info).with(
          "Shopify productUpdate query cost: requested=10 actual=10 " \
          "available=1990.0/2000.0 restore_rate=100.0"
        )
      end
    end

    context "when API errors occur" do
      let(:error_response) do
        double(body: {
          "data" => {
            "productUpdate" => {
              "userErrors" => []
            }
          },
          "errors" => [
            {"message" => "Product not found"}
          ]
        })
      end

      before do
        allow(mock_graphql_client).to receive(:query).and_return(error_response)
        allow(Sentry).to receive(:capture_message)
      end

      it "captures error in Sentry and raises ApiError" do
        expect(Sentry).to receive(:capture_message)
        expect { client.update_product(product_id, serialized_product) }.to raise_error(described_class::ApiError)
      end
    end

    context "when user errors occur" do
      let(:error_response) do
        double(body: {
          "data" => {
            "productUpdate" => {
              "userErrors" => [
                {"field" => ["title"], "message" => "Title cannot be blank"}
              ]
            }
          }
        })
      end

      before do
        allow(mock_graphql_client).to receive(:query).and_return(error_response)
        allow(Sentry).to receive(:capture_message)
      end

      it "captures error in Sentry and raises ApiError" do
        expect(Sentry).to receive(:capture_message)
        expect { client.update_product(product_id, serialized_product) }.to raise_error(described_class::ApiError)
      end
    end
  end

  describe "#create_product_options" do
    let(:product_id) { "gid://shopify/Product/123" }
    let(:options) do
      [
        {name: "Size", values: [{name: "Large"}, {name: "Medium"}]},
        {name: "Color", values: [{name: "Red"}]}
      ]
    end
    let(:success_response) do
      double(body: {
        "data" => {
          "productOptionsCreate" => {
            "userErrors" => [],
            "product" => {
              "id" => product_id,
              "options" => [
                {
                  "id" => "gid://shopify/ProductOption/456",
                  "name" => "Size",
                  "values" => ["Large", "Medium"]
                }
              ]
            }
          }
        }
      })
    end

    before do
      allow(mock_graphql_client).to receive(:query).and_return(success_response)
    end

    it "executes the product options create mutation" do
      client.create_product_options(product_id, options)

      expect(mock_graphql_client).to have_received(:query).with(
        query: kind_of(String),
        variables: {
          productId: product_id,
          options: options,
          variantStrategy: "CREATE"
        }
      )
    end

    it "returns the product data with options" do
      result = client.create_product_options(product_id, options)
      expect(result).to eq(success_response.body.dig("data", "productOptionsCreate", "product"))
    end

    context "when API errors occur" do
      let(:error_response) do
        double(body: {
          "data" => {
            "productOptionsCreate" => {
              "userErrors" => []
            }
          },
          "errors" => [
            {"message" => "Product not found"}
          ]
        })
      end

      before do
        allow(mock_graphql_client).to receive(:query).and_return(error_response)
        allow(Sentry).to receive(:capture_message)
      end

      it "captures error in Sentry and raises ApiError" do
        expect(Sentry).to receive(:capture_message)
        expect { client.create_product_options(product_id, options) }.to raise_error(described_class::ApiError)
      end
    end

    context "when user errors occur" do
      let(:error_response) do
        double(body: {
          "data" => {
            "productOptionsCreate" => {
              "userErrors" => [
                {"field" => ["options"], "message" => "Can only specify a maximum of 3 options"}
              ]
            }
          }
        })
      end

      before do
        allow(mock_graphql_client).to receive(:query).and_return(error_response)
        allow(Sentry).to receive(:capture_message)
      end

      it "captures error in Sentry and raises ApiError" do
        expect(Sentry).to receive(:capture_message)
        expect { client.create_product_options(product_id, options) }.to raise_error(described_class::ApiError)
      end
    end
  end

  describe "#attach_media" do
    let(:product_id) { "gid://shopify/Product/123" }
    let(:media_input) do
      [
        {
          mediaContentType: "IMAGE",
          alt: "Product view",
          originalSource: "https://example.com/image1.jpg"
        },
        {
          mediaContentType: "IMAGE",
          alt: "Product detail",
          originalSource: "https://example.com/image2.jpg"
        }
      ]
    end
    let(:success_response) do
      double(body: {
        "data" => {
          "productUpdate" => {
            "product" => {
              "id" => product_id,
              "media" => {
                "nodes" => [
                  {
                    "id" => "gid://shopify/MediaImage/456",
                    "alt" => "Product view",
                    "status" => "UPLOADED",
                    "fileStatus" => "READY"
                  },
                  {
                    "id" => "gid://shopify/MediaImage/457",
                    "alt" => "Product detail",
                    "status" => "UPLOADED",
                    "fileStatus" => "READY"
                  }
                ]
              }
            },
            "userErrors" => []
          }
        }
      })
    end

    before do
      allow(mock_graphql_client).to receive(:query).and_return(success_response)
    end

    it "returns empty array when media_input is blank" do
      expect(mock_graphql_client).not_to receive(:query)
      expect(client.attach_media(product_id, nil)).to eq([])
      expect(client.attach_media(product_id, [])).to eq([])
    end

    it "executes the media attach mutation" do
      client.attach_media(product_id, media_input)

      expect(mock_graphql_client).to have_received(:query).with(
        query: kind_of(String),
        variables: {
          product: {id: product_id},
          media: media_input
        }
      )
    end

    it "returns array of media nodes on success" do
      result = client.attach_media(product_id, media_input)

      expect(result).to be_an(Array)
      expect(result.size).to eq(2)
      expect(result.first["id"]).to eq("gid://shopify/MediaImage/456")
    end

    context "when Shopify is still processing the attached media" do
      let(:processing_nodes) do
        [
          {"id" => "gid://shopify/MediaImage/456", "status" => "UPLOADED", "fileStatus" => "PROCESSING"},
          {"id" => "gid://shopify/MediaImage/457", "status" => "PROCESSING", "fileStatus" => "PROCESSING"}
        ]
      end
      let(:processing_response) do
        double(body: {
          "data" => {
            "productUpdate" => {
              "product" => {"id" => product_id, "media" => {"nodes" => processing_nodes}},
              "userErrors" => []
            }
          }
        })
      end

      it "returns the nodes at once without polling their status" do
        allow(mock_graphql_client).to receive(:query).and_invoke(
          ->(**) { processing_response },
          ->(**) { raise "polled Shopify for media status" }
        )

        expect(client.attach_media(product_id, media_input)).to eq(processing_nodes)
      end
    end

    context "when API errors occur" do
      let(:error_response) do
        double(body: {
          "data" => {
            "productUpdate" => {
              "userErrors" => []
            }
          },
          "errors" => [
            {"message" => "Invalid image URL"}
          ]
        })
      end

      before do
        allow(mock_graphql_client).to receive(:query).and_return(error_response)
        allow(Sentry).to receive(:capture_message)
      end

      it "captures error in Sentry and raises ApiError" do
        expect(Sentry).to receive(:capture_message)
        expect { client.attach_media(product_id, media_input) }.to raise_error(described_class::ApiError)
      end
    end

    context "when user errors occur" do
      let(:error_response) do
        double(body: {
          "data" => {
            "productUpdate" => {
              "userErrors" => [
                {"field" => ["media", 0, "originalSource"], "message" => "URL is not valid"}
              ]
            }
          }
        })
      end

      before do
        allow(mock_graphql_client).to receive(:query).and_return(error_response)
        allow(Sentry).to receive(:capture_message)
      end

      it "captures error in Sentry and raises ApiError" do
        expect(Sentry).to receive(:capture_message)
        expect { client.attach_media(product_id, media_input) }.to raise_error(described_class::ApiError)
      end
    end

    context "when media user errors occur" do
      let(:error_response) do
        double(body: {
          "data" => {
            "productUpdate" => {
              "mediaUserErrors" => [
                {"field" => ["media", 0], "message" => "Image could not be downloaded"}
              ]
            }
          }
        })
      end

      before do
        allow(mock_graphql_client).to receive(:query).and_return(error_response)
        allow(Sentry).to receive(:capture_message)
      end

      it "captures error in Sentry and raises ApiError" do
        expect(Sentry).to receive(:capture_message)
        expect { client.attach_media(product_id, media_input) }.to raise_error(described_class::ApiError)
      end
    end
  end

  describe "#update_media" do
    let(:file_updates) do
      [
        {
          id: "gid://shopify/MediaImage/456",
          originalSource: "https://example.com/image1.jpg",
          alt: "Updated product view"
        }
      ]
    end
    let(:success_response) do
      double(body: {
        "data" => {
          "fileUpdate" => {
            "files" => [
              {
                "id" => "gid://shopify/MediaImage/456",
                "alt" => "Updated product view"
              }
            ],
            "userErrors" => []
          }
        }
      })
    end

    before do
      allow(mock_graphql_client).to receive(:query).and_return(success_response)
    end

    it "returns empty array when file_updates is blank" do
      expect(mock_graphql_client).not_to receive(:query)
      expect(client.update_media(nil)).to eq([])
      expect(client.update_media([])).to eq([])
    end

    it "executes the media update mutation" do
      client.update_media(file_updates)

      expect(mock_graphql_client).to have_received(:query).with(
        query: kind_of(String),
        variables: {
          files: file_updates
        }
      )
    end

    it "returns array of updated files" do
      result = client.update_media(file_updates)
      expect(result).to be_an(Array)
      expect(result.first["id"]).to eq("gid://shopify/MediaImage/456")
    end

    context "when API errors occur" do
      let(:error_response) do
        double(body: {
          "data" => {
            "fileUpdate" => {
              "userErrors" => []
            }
          },
          "errors" => [
            {"message" => "Invalid file ID"}
          ]
        })
      end

      before do
        allow(mock_graphql_client).to receive(:query).and_return(error_response)
        allow(Sentry).to receive(:capture_message)
      end

      it "captures error in Sentry and raises ApiError" do
        expect(Sentry).to receive(:capture_message)
        expect { client.update_media(file_updates) }.to raise_error(described_class::ApiError)
      end
    end
  end

  describe "#reorder_media" do
    let(:product_id) { "gid://shopify/Product/123" }
    let(:moves) do
      [
        {id: "gid://shopify/MediaImage/456", newPosition: 0},
        {id: "gid://shopify/MediaImage/457", newPosition: 1}
      ]
    end
    let(:success_response) do
      double(body: {
        "data" => {
          "productReorderMedia" => {
            "job" => {
              "id" => "gid://shopify/Job/789",
              "done" => true
            },
            "mediaUserErrors" => []
          }
        }
      })
    end

    before do
      allow(mock_graphql_client).to receive(:query).and_return(success_response)
    end

    it "does nothing when moves is blank" do
      expect(mock_graphql_client).not_to receive(:query)
      expect(client.reorder_media(product_id, nil)).to be_nil
      expect(client.reorder_media(product_id, [])).to be_nil
    end

    it "executes the media reorder mutation" do
      client.reorder_media(product_id, moves)

      expect(mock_graphql_client).to have_received(:query).with(
        query: kind_of(String),
        variables: {
          id: product_id,
          moves: moves
        }
      )
    end

    it "returns job info on success" do
      result = client.reorder_media(product_id, moves)
      expect(result).to eq({
        "id" => "gid://shopify/Job/789",
        "done" => true
      })
    end

    context "when API errors occur" do
      let(:error_response) do
        double(body: {
          "data" => {
            "productReorderMedia" => {
              "mediaUserErrors" => []
            }
          },
          "errors" => [
            {"message" => "Product not found"}
          ]
        })
      end

      before do
        allow(mock_graphql_client).to receive(:query).and_return(error_response)
        allow(Sentry).to receive(:capture_message)
      end

      it "captures error in Sentry and raises ApiError" do
        expect(Sentry).to receive(:capture_message)
        expect { client.reorder_media(product_id, moves) }.to raise_error(described_class::ApiError)
      end
    end

    context "when media user errors occur" do
      let(:error_response) do
        double(body: {
          "data" => {
            "productReorderMedia" => {
              "mediaUserErrors" => [
                {"field" => ["moves", 0, "id"], "message" => "Media not found"}
              ]
            }
          }
        })
      end

      before do
        allow(mock_graphql_client).to receive(:query).and_return(error_response)
        allow(Sentry).to receive(:capture_message)
      end

      it "captures error in Sentry and raises ApiError" do
        expect(Sentry).to receive(:capture_message)
        expect { client.reorder_media(product_id, moves) }.to raise_error(described_class::ApiError)
      end
    end
  end

  describe "#extract_pagination" do
    let(:response_data) do
      {
        "products" => {
          "edges" => [
            {"node" => {"id" => "1"}},
            {"node" => {"id" => "2"}}
          ],
          "pageInfo" => {
            "hasNextPage" => true,
            "endCursor" => "cursor123"
          }
        }
      }
    end

    it "extracts items and pagination info" do
      result = client.send(:extract_pagination, response_data, resource_name: "products")

      expect(result[:items]).to eq([{"id" => "1"}, {"id" => "2"}])
      expect(result[:has_next_page]).to be(true)
      expect(result[:end_cursor]).to eq("cursor123")
    end
  end

  describe "#handle_query_errors" do
    context "when errors are present" do
      let(:response) do
        double(body: {
          "errors" => [
            {"message" => "Authentication error"},
            {"message" => "Invalid token"}
          ]
        })
      end

      it "raises ApiError with resource name and error messages" do
        expect {
          client.send(:handle_query_errors, response, resource_name: "products")
        }.to raise_error(described_class::ApiError, "Failed to fetch products: Authentication error, Invalid token")
      end
    end

    context "when no errors are present" do
      let(:response) do
        double(body: {
          "data" => {"products" => {"edges" => []}}
        })
      end

      it "does not raise an error" do
        expect {
          client.send(:handle_query_errors, response, resource_name: "products")
        }.not_to raise_error
      end
    end

    context "when errors array is empty" do
      let(:response) do
        double(body: {
          "errors" => []
        })
      end

      it "raises ApiError with empty message since empty array is truthy" do
        expect {
          client.send(:handle_query_errors, response, resource_name: "products")
        }.to raise_error(described_class::ApiError, "Failed to fetch products: ")
      end
    end
  end

  describe "#handle_mutation_errors" do
    let(:query) { "mutation { productCreate(input: {}) }" }

    context "when API errors are present" do
      let(:response) do
        double(body: {
          "data" => {
            "productCreate" => {"userErrors" => []}
          },
          "errors" => [
            {"message" => "Rate limit exceeded"}
          ]
        })
      end

      before do
        allow(Sentry).to receive(:capture_message)
      end

      it "captures error in Sentry and raises ApiError" do
        expect(Sentry).to receive(:capture_message).with(
          "Shopify productCreate failed: Rate limit exceeded",
          level: :error,
          tags: {api: "shopify", operation: "productCreate"},
          extra: {query:, shopify_errors: [{"message" => "Rate limit exceeded"}]}
        )

        expect {
          client.send(:handle_mutation_errors, response, "productCreate", query:)
        }.to raise_error(described_class::ApiError, "Failed to call the productCreate API mutation: Rate limit exceeded")
      end
    end

    context "when user errors are present" do
      let(:response) do
        double(body: {
          "data" => {
            "productCreate" => {
              "userErrors" => [
                {"field" => ["title"], "message" => "Title is required"}
              ]
            }
          }
        })
      end

      before do
        allow(Sentry).to receive(:capture_message)
      end

      it "captures error in Sentry and raises ApiError" do
        expect(Sentry).to receive(:capture_message).with(
          "Shopify productCreate failed: Title is required",
          level: :error,
          tags: {api: "shopify", operation: "productCreate"},
          extra: {query:, shopify_errors: nil}
        )

        expect {
          client.send(:handle_mutation_errors, response, "productCreate", query:)
        }.to raise_error(described_class::ApiError, "Failed to call the productCreate API mutation: Title is required")
      end
    end

    context "when media user errors are present" do
      let(:response) do
        double(body: {
          "data" => {
            "productUpdate" => {
              "mediaUserErrors" => [
                {"field" => ["media", 0], "message" => "Image download failed"}
              ]
            }
          }
        })
      end

      before do
        allow(Sentry).to receive(:capture_message)
      end

      it "captures error in Sentry and raises ApiError" do
        expect(Sentry).to receive(:capture_message).with(
          "Shopify productUpdate failed: Image download failed",
          level: :error,
          tags: {api: "shopify", operation: "productUpdate"},
          extra: {query:, shopify_errors: nil}
        )

        expect {
          client.send(:handle_mutation_errors, response, "productUpdate", query:)
        }.to raise_error(described_class::ApiError, "Failed to call the productUpdate API mutation: Image download failed")
      end
    end

    context "when no errors are present" do
      let(:response) do
        double(body: {
          "data" => {
            "productCreate" => {
              "product" => {"id" => "123"},
              "userErrors" => []
            }
          }
        })
      end

      it "does not raise an error or capture to Sentry" do
        expect(Sentry).not_to receive(:capture_message)
        expect {
          client.send(:handle_mutation_errors, response, "productCreate", query:)
        }.not_to raise_error
      end
    end

    context "when user errors array is empty" do
      let(:response) do
        double(body: {
          "data" => {
            "productCreate" => {
              "userErrors" => []
            }
          }
        })
      end

      it "does not raise an error or capture to Sentry" do
        expect(Sentry).not_to receive(:capture_message)
        expect {
          client.send(:handle_mutation_errors, response, "productCreate", query:)
        }.not_to raise_error
      end
    end
  end

  describe "::ApiError" do
    it "is a StandardError subclass" do
      expect(described_class::ApiError.new).to be_a(StandardError)
    end

    it "can be instantiated with a message" do
      error = described_class::ApiError.new("Test error")
      expect(error.message).to eq("Test error")
    end

    it "can be raised and rescued" do
      expect {
        raise described_class::ApiError, "Test error"
      }.to raise_error(described_class::ApiError, "Test error")
    end
  end
end
