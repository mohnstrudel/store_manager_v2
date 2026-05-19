# frozen_string_literal: true

# == Schema Information
#
# Table name: sale_addresses
#
#  id         :bigint           not null, primary key
#  address_1  :string
#  address_2  :string
#  city       :string
#  company    :string
#  country    :string
#  email      :string
#  first_name :string
#  kind       :integer          not null
#  last_name  :string
#  phone      :string
#  postcode   :string
#  state      :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  sale_id    :bigint           not null
#
require "rails_helper"

RSpec.describe SaleAddress do
  describe "validations" do
    it "allows one address per kind for each sale", :aggregate_failures do
      sale = create(:sale)
      create(:sale_address, sale:, kind: :shipping)

      duplicate = build(:sale_address, sale:, kind: :shipping)

      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:kind]).to be_present
    end

    it "allows shipping and billing addresses for the same sale" do
      sale = create(:sale)
      create(:sale_address, sale:, kind: :shipping)

      billing = build(:sale_address, sale:, kind: :billing)

      expect(billing).to be_valid
    end
  end
end
