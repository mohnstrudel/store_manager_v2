# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Conditional GET" do
  before do
    sign_in_as_admin
    create(:brand)
  end

  around do |example|
    original_version = InertiaRails.configuration.version
    example.run
  ensure
    InertiaRails.configuration.version = original_version
  end

  it "answers not modified while the records and asset version are unchanged" do
    get brands_path
    get brands_path, headers: {"If-None-Match" => response.headers["ETag"]}

    expect(response).to have_http_status(:not_modified)
  end

  it "renders the page again after the asset version changes" do
    get brands_path
    etag = response.headers["ETag"]
    InertiaRails.configuration.version = "next-deploy"

    get brands_path, headers: {"If-None-Match" => etag}

    expect(response).to have_http_status(:ok)
  end

  it "does not answer an Inertia visit with the HTML page validator" do
    get brands_path
    inertia_headers = {"X-Inertia" => "true", "X-Inertia-Version" => InertiaRails.configuration.version.to_s}

    get brands_path, headers: inertia_headers.merge("If-None-Match" => response.headers["ETag"])

    expect(response).to have_http_status(:ok)
  end
end
