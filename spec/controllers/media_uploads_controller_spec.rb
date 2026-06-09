# frozen_string_literal: true

require "rails_helper"

RSpec.describe MediaUploadsController do
  before { sign_in_as_admin }
  after { log_out }

  def minimal_jpeg(filename: "test.jpg")
    tempfile = Tempfile.new(["upload_test", ".jpg"])
    tempfile.binmode
    tempfile.write("\xFF\xD8\xFF\xE0\x00\x10JFIF\x00\x01\x01\x00\x00\x01\x00\x01\x00\x00\xFF\xD9")
    tempfile.rewind
    Rack::Test::UploadedFile.new(tempfile.path, "image/jpeg", original_filename: filename)
  end

  describe "POST #create" do
    context "with a valid image file" do
      it "returns a signed_id and creates a blob" do
        expect {
          post :create, params: {file: minimal_jpeg}
        }.to change(ActiveStorage::Blob, :count).by(1)

        expect(response).to have_http_status(:ok)
        body = response.parsed_body
        expect(body["signed_id"]).to be_present
        expect(ActiveStorage::Blob.find_signed(body["signed_id"])).to be_a(ActiveStorage::Blob)
      end
    end

    context "without a file" do
      it "returns 422" do
        post :create, params: {}

        expect(response).to have_http_status(:unprocessable_content)
      end
    end
  end
end
