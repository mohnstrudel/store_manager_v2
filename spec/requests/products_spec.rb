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
end
