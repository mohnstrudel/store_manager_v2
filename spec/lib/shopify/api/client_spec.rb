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

  describe "#execute" do
    it "executes a GraphQL query with variables" do
      allow(mock_graphql_client).to receive(:query).and_return(double(body: {"data" => {"shop" => {"name" => "test"}}}))

      response = client.execute("query { shop { name } }", variables: {})

      expect(response).to be_present
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
      expect { client.fetch_product(nil) }.to raise_error(ArgumentError, "Product ID is required")
      expect { client.fetch_product("") }.to raise_error(ArgumentError, "Product ID is required")
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

    it "returns structured response with items and pagination info" do
      result = client.fetch_products(cursor: cursor, batch_size: batch_size)

      expect(result[:items]).to eq([
        {"id" => "gid://shopify/Product/1", "title" => "Product 1"},
        {"id" => "gid://shopify/Product/2", "title" => "Product 2"}
      ])
      expect(result[:has_next_page]).to be(true)
      expect(result[:end_cursor]).to eq("next_cursor")
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
            "totalPrice" => "99.99"
          }
        }
      })
    end

    before do
      allow(mock_graphql_client).to receive(:query).and_return(order_response)
    end

    it "raises ArgumentError when order_id is blank" do
      expect { client.fetch_order(nil) }.to raise_error(ArgumentError, "Order ID is required")
      expect { client.fetch_order("") }.to raise_error(ArgumentError, "Order ID is required")
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

    it "returns structured response with items and pagination info" do
      result = client.fetch_orders(cursor: cursor, batch_size: batch_size)

      expect(result[:items]).to eq([
        {"id" => "gid://shopify/Order/1", "name" => "#1001"},
        {"id" => "gid://shopify/Order/2", "name" => "#1002"}
      ])
      expect(result[:has_next_page]).to be(false)
      expect(result[:end_cursor]).to be_nil
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

  describe "#wait_until_media_ready" do
    let(:media_nodes) do
      [
        {
          "id" => "gid://shopify/MediaImage/456",
          "status" => "UPLOADED",
          "fileStatus" => "PROCESSING"
        }
      ]
    end

    before do
      allow(client).to receive(:query_media_status).and_return(
        {"id" => "gid://shopify/MediaImage/456", "status" => "READY", "fileStatus" => "READY"}
      )
      allow(client).to receive(:sleep)
    end

    it "waits until media status is READY" do
      client.send(:wait_until_media_ready, media_nodes, timeout: 1, interval: 0)
      expect(client).to have_received(:query_media_status).with("gid://shopify/MediaImage/456")
    end

    it "returns when status is already READY" do
      ready_nodes = [
        {"id" => "gid://shopify/MediaImage/456", "status" => "READY", "fileStatus" => "READY"}
      ]
      client.send(:wait_until_media_ready, ready_nodes, timeout: 1, interval: 0)
      expect(client).not_to have_received(:query_media_status)
    end

    it "returns when fileStatus is READY" do
      ready_nodes = [
        {"id" => "gid://shopify/MediaImage/456", "status" => "UPLOADED", "fileStatus" => "READY"}
      ]
      client.send(:wait_until_media_ready, ready_nodes, timeout: 1, interval: 0)
      expect(client).not_to have_received(:query_media_status)
    end

    it "raises ApiError when timeout is exceeded" do
      allow(client).to receive(:query_media_status).and_return(
        {"id" => "gid://shopify/MediaImage/456", "status" => "PROCESSING", "fileStatus" => "PROCESSING"}
      )

      expect {
        client.send(:wait_until_media_ready, media_nodes, timeout: 0, interval: 0)
      }.to raise_error(described_class::ApiError, /failed to become ready within 0 seconds/)
    end

    it "does nothing when media_nodes is blank" do
      client.send(:wait_until_media_ready, [], timeout: 1, interval: 0)
      expect(client).not_to have_received(:query_media_status)
    end
  end

  describe "#query_media_status" do
    let(:media_id) { "gid://shopify/MediaImage/456" }
    let(:status_response) do
      double(body: {
        "data" => {
          "node" => {
            "id" => media_id,
            "status" => "READY",
            "fileStatus" => "READY"
          }
        }
      })
    end

    before do
      allow(mock_graphql_client).to receive(:query).and_return(status_response)
    end

    it "queries media status with correct ID" do
      result = client.send(:query_media_status, media_id)
      expect(result).to eq(status_response.body.dig("data", "node"))
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
        # The implementation returns unless errors, but empty array is truthy
        # So it will raise with an empty message
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
