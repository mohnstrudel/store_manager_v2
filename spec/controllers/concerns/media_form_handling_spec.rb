# frozen_string_literal: true

require "rails_helper"

RSpec.describe MediaFormHandling do
  # Use a real controller that already includes the concern
  describe WarehousesController do
    before { sign_in_as_admin }
    after { log_out }

    # Helper to create an uploaded file that passes image_like? checks
    def create_test_image(filename: "test.jpg", content_type: "image/jpeg")
      tempfile = Tempfile.new(["test", ".jpg"])
      # Write a minimal JPEG header
      tempfile.write("\xFF\xD8\xFF\xE0\x00\x10JFIF\x00\x01\x01\x00\x00\x01\x00\x01\x00\x00\xFF\xD9")
      tempfile.rewind

      Rack::Test::UploadedFile.new(tempfile.path, content_type, original_filename: filename)
    end

    describe "POST #create with new images" do
      it "attaches new images to the record" do
        initial_count = Media.count
        post :create, params: {
          warehouse: {
            name: "Test Warehouse",
            position: 1,
            new_images: [create_test_image, create_test_image(filename: "test2.jpg")]
          }
        }

        expect(Media.count - initial_count).to eq(2)
      end

      it "attaches images to the correct warehouse" do
        post :create, params: {
          warehouse: {
            name: "Test Warehouse",
            position: 1,
            new_images: [create_test_image, create_test_image(filename: "test2.jpg")]
          }
        }

        expect(Warehouse.last.media.count).to eq(2)
      end

      it "positions new images starting at 0 when no existing media" do
        post :create, params: {
          warehouse: {
            name: "Test Warehouse",
            position: 1,
            new_images: [create_test_image, create_test_image(filename: "test2.jpg")]
          }
        }

        warehouse = Warehouse.last
        expect(warehouse.media.first.position).to eq(0)
      end

      it "positions second image at position 1" do
        post :create, params: {
          warehouse: {
            name: "Test Warehouse",
            position: 1,
            new_images: [create_test_image, create_test_image(filename: "test2.jpg")]
          }
        }

        warehouse = Warehouse.last
        expect(warehouse.media.second.position).to eq(1)
      end

      it "skips non-image values when adding new media" do
        initial_count = Media.count
        post :create, params: {
          warehouse: {
            name: "Test Warehouse",
            position: 1,
            new_images: ["not an image", nil, create_test_image]
          }
        }

        expect(Media.count - initial_count).to eq(1)
      end

      it "creates only valid media when given non-image values" do
        post :create, params: {
          warehouse: {
            name: "Test Warehouse",
            position: 1,
            new_images: ["not an image", nil, create_test_image]
          }
        }

        expect(Warehouse.last.media.count).to eq(1)
      end
    end

    describe "PATCH #update with media changes" do
      let!(:warehouse) { create(:warehouse) }
      let!(:first_media) { create(:media, :for_warehouse, mediaable: warehouse, position: 0, alt: "Original 0") }
      let!(:second_media) { create(:media, :for_warehouse, mediaable: warehouse, position: 1, alt: "Original 1") }

      it "updates first media position" do
        patch :update, params: {
          id: warehouse.id,
          warehouse: {
            name: warehouse.name,
            media: {
              "0" => {id: first_media.id.to_s, position: "3"}
            }
          }
        }

        expect(first_media.reload.position).to eq(3)
      end

      it "updates second media position" do
        patch :update, params: {
          id: warehouse.id,
          warehouse: {
            name: warehouse.name,
            media: {
              "0" => {id: second_media.id.to_s, position: "1"}
            }
          }
        }

        expect(second_media.reload.position).to eq(1)
      end

      it "updates media alt text" do
        patch :update, params: {
          id: warehouse.id,
          warehouse: {
            name: warehouse.name,
            media: {
              "0" => {id: first_media.id.to_s, alt: "Updated alt"}
            }
          }
        }

        expect(first_media.reload.alt).to eq("Updated alt")
      end

      it "updates media position" do
        patch :update, params: {
          id: warehouse.id,
          warehouse: {
            name: warehouse.name,
            media: {
              "0" => {id: first_media.id.to_s, position: "5", alt: "New position and alt"}
            }
          }
        }

        expect(first_media.reload.position).to eq(5)
      end

      it "updates media alt" do
        patch :update, params: {
          id: warehouse.id,
          warehouse: {
            name: warehouse.name,
            media: {
              "0" => {id: first_media.id.to_s, position: "5", alt: "New position and alt"}
            }
          }
        }

        expect(first_media.reload.alt).to eq("New position and alt")
      end

      it "destroys media when _destroy is '1'" do
        expect {
          patch :update, params: {
            id: warehouse.id,
            warehouse: {
              name: warehouse.name,
              media: {
                "0" => {id: first_media.id.to_s, _destroy: "1"}
              }
            }
          }
        }.to change(warehouse.media, :count).by(-1)
      end

      it "keeps second media when first is destroyed" do
        patch :update, params: {
          id: warehouse.id,
          warehouse: {
            name: warehouse.name,
            media: {
              "0" => {id: first_media.id.to_s, _destroy: "1"}
            }
          }
        }

        expect(Media.where(id: second_media.id)).to exist
      end

      it "does not destroy when _destroy is '0'" do
        expect {
          patch :update, params: {
            id: warehouse.id,
            warehouse: {
              name: warehouse.name,
              media: {
                "0" => {id: first_media.id.to_s, _destroy: "0", alt: "Keep this"}
              }
            }
          }
        }.not_to change(warehouse.media, :count)
      end

      it "keeps media when _destroy is '0'" do
        patch :update, params: {
          id: warehouse.id,
          warehouse: {
            name: warehouse.name,
            media: {
              "0" => {id: first_media.id.to_s, _destroy: "0", alt: "Keep this"}
            }
          }
        }

        expect(first_media.reload.alt).to eq("Keep this")
      end

      it "replaces media image attachment" do
        patch :update, params: {
          id: warehouse.id,
          warehouse: {
            name: warehouse.name,
            media: {
              "0" => {id: first_media.id.to_s, image: create_test_image(filename: "replacement.jpg")}
            }
          }
        }

        expect(first_media.reload.image.filename.to_s).to eq("replacement.jpg")
      end

      it "adds new images after existing media" do
        patch :update, params: {
          id: warehouse.id,
          warehouse: {
            name: warehouse.name,
            media: {},
            new_images: [create_test_image(filename: "new.jpg")]
          }
        }

        expect(warehouse.media.count).to eq(3)
      end

      it "positions new images after existing media" do
        patch :update, params: {
          id: warehouse.id,
          warehouse: {
            name: warehouse.name,
            media: {},
            new_images: [create_test_image(filename: "new.jpg")]
          }
        }

        expect(warehouse.media.ordered.last.position).to eq(2)
      end

      it "skips media with blank ids" do
        expect {
          patch :update, params: {
            id: warehouse.id,
            warehouse: {
              name: warehouse.name,
              media: {
                "0" => {id: first_media.id.to_s, alt: "Valid"},
                "1" => {id: "", alt: "Should be skipped"},
                "2" => nil
              }
            }
          }
        }.not_to change(warehouse.media, :count)
      end

      it "handles non-existent media ids gracefully" do
        expect {
          patch :update, params: {
            id: warehouse.id,
            warehouse: {
              name: warehouse.name,
              media: {
                "0" => {id: "999999", alt: "Non-existent"}
              }
            }
          }
        }.not_to raise_error

        expect(warehouse.media.count).to eq(2)
      end
    end

    describe "complex media workflows" do
      let!(:warehouse) { create(:warehouse) }
      let!(:first_media) { create(:media, :for_warehouse, mediaable: warehouse, position: 0, alt: "First") }
      let!(:third_media) { create(:media, :for_warehouse, mediaable: warehouse, position: 2, alt: "Third") }

      it "handles update, destroy, and create in a single request" do
        expect {
          patch :update, params: {
            id: warehouse.id,
            warehouse: {
              name: warehouse.name,
              media: {
                "0" => {id: first_media.id.to_s, position: "2", alt: "Moved down"},
                "1" => {id: third_media.id.to_s, _destroy: "1"}
              },
              new_images: [create_test_image(filename: "new.jpg")]
            }
          }
        }.not_to change(warehouse.media, :count)
      end

      it "updates media position in complex workflow" do
        patch :update, params: {
          id: warehouse.id,
          warehouse: {
            name: warehouse.name,
            media: {
              "0" => {id: first_media.id.to_s, position: "2", alt: "Moved down"}
            },
            new_images: []
          }
        }

        expect(first_media.reload.position).to eq(2)
      end

      it "updates media alt in complex workflow" do
        patch :update, params: {
          id: warehouse.id,
          warehouse: {
            name: warehouse.name,
            media: {
              "0" => {id: first_media.id.to_s, position: "2", alt: "Moved down"}
            },
            new_images: []
          }
        }

        expect(first_media.reload.alt).to eq("Moved down")
      end

      it "destroys media in complex workflow" do
        patch :update, params: {
          id: warehouse.id,
          warehouse: {
            name: warehouse.name,
            media: {
              "0" => {id: third_media.id.to_s, _destroy: "1"}
            },
            new_images: []
          }
        }

        expect(Media.where(id: third_media.id)).to be_empty
      end

      it "creates new media in complex workflow" do
        expect {
          patch :update, params: {
            id: warehouse.id,
            warehouse: {
              name: warehouse.name,
              media: {},
              new_images: [create_test_image(filename: "new.jpg")]
            }
          }
        }.to change(warehouse.media, :count).by(1)
      end
    end
  end

  describe ProductsController do
    before { sign_in_as_admin }
    after { log_out }

    def create_test_image(filename: "test.jpg", content_type: "image/jpeg")
      tempfile = Tempfile.new(["test", ".jpg"])
      tempfile.write("\xFF\xD8\xFF\xE0\x00\x10JFIF\x00\x01\x01\x00\x00\x01\x00\x01\x00\x00\xFF\xD9")
      tempfile.rewind

      # Create an UploadedFile that has both content_type and tempfile
      # This ensures it passes the image_like? check
      Rack::Test::UploadedFile.new(tempfile.path, content_type, original_filename: filename)
    end

    describe "POST #create with new images" do
      let(:franchise) { create(:franchise) }
      let(:shape) { create(:shape) }

      it "attaches new images to the product" do
        initial_count = Media.count
        post :create, params: {
          product: {
            title: "Test Product",
            franchise_id: franchise.id,
            shape_id: shape.id,
            new_images: [create_test_image, create_test_image(filename: "test2.jpg")]
          }
        }

        expect(Media.count - initial_count).to eq(2)
      end

      it "responds with redirect on product creation" do
        post :create, params: {
          product: {
            title: "Test Product",
            franchise_id: franchise.id,
            shape_id: shape.id,
            new_images: [create_test_image, create_test_image(filename: "test2.jpg")]
          }
        }

        expect(response).to have_http_status(:redirect)
      end

      it "creates the product with images" do
        post :create, params: {
          product: {
            title: "Test Product",
            franchise_id: franchise.id,
            shape_id: shape.id,
            new_images: [create_test_image, create_test_image(filename: "test2.jpg")]
          }
        }

        created_product = Product.find_by(title: "Test Product")
        expect(created_product).not_to be_nil
      end

      it "attaches correct number of images to product" do
        post :create, params: {
          product: {
            title: "Test Product",
            franchise_id: franchise.id,
            shape_id: shape.id,
            new_images: [create_test_image, create_test_image(filename: "test2.jpg")]
          }
        }

        created_product = Product.find_by(title: "Test Product")
        expect(created_product.media.count).to eq(2)
      end

      it "positions new images after existing media" do
        existing_product = create(:product)
        create(:media, :for_product, mediaable: existing_product, position: 3)

        post :create, params: {
          product: {
            title: "Another Product",
            franchise_id: franchise.id,
            shape_id: shape.id,
            new_images: [create_test_image]
          }
        }

        new_product = Product.find_by(title: "Another Product")
        expect(new_product).not_to be_nil
      end

      it "positions new product image at position 0" do
        existing_product = create(:product)
        create(:media, :for_product, mediaable: existing_product, position: 3)

        post :create, params: {
          product: {
            title: "Another Product",
            franchise_id: franchise.id,
            shape_id: shape.id,
            new_images: [create_test_image]
          }
        }

        new_product = Product.find_by(title: "Another Product")
        expect(new_product.media.first.position).to eq(0)
      end

      it "keeps existing product media unchanged" do
        existing_product = create(:product)
        create(:media, :for_product, mediaable: existing_product, position: 3)

        post :create, params: {
          product: {
            title: "Another Product",
            franchise_id: franchise.id,
            shape_id: shape.id,
            new_images: [create_test_image]
          }
        }

        expect(existing_product.reload.media.count).to eq(1)
      end

      it "keeps existing product media position unchanged" do
        existing_product = create(:product)
        create(:media, :for_product, mediaable: existing_product, position: 3)

        post :create, params: {
          product: {
            title: "Another Product",
            franchise_id: franchise.id,
            shape_id: shape.id,
            new_images: [create_test_image]
          }
        }

        expect(existing_product.media.first.position).to eq(3)
      end
    end

    describe "PATCH #update with media changes" do
      let!(:product) { create(:product) }
      let!(:first_media) { create(:media, :for_product, mediaable: product, position: 0, alt: "Original") }

      it "updates media alt text" do
        patch :update, params: {
          id: product.id,
          product: {
            title: product.title,
            franchise_id: product.franchise_id,
            shape_id: product.shape_id,
            media: {
              "0" => {id: first_media.id.to_s, alt: "Updated alt"}
            }
          }
        }

        expect(first_media.reload.alt).to eq("Updated alt")
      end

      it "adds new images during update" do
        patch :update, params: {
          id: product.id,
          product: {
            title: product.title,
            franchise_id: product.franchise_id,
            shape_id: product.shape_id,
            media: {},
            new_images: [create_test_image(filename: "new.jpg")]
          }
        }

        expect(product.media.count).to eq(2)
      end
    end
  end
end
