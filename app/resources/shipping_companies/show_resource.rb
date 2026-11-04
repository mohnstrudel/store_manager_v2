# frozen_string_literal: true

class ShippingCompanies::ShowResource < ApplicationResource
  typelize "Array<ShippingCompaniesPurchaseItem>"
  attribute :purchaseItems do |page|
    ShippingCompanies::PurchaseItemResource.new(page.fetch(:purchase_items)).serializable_hash
  end

  typelize "ShippingCompany"
  attribute :shippingCompany do |page|
    ShippingCompanyResource.new(page.fetch(:shipping_company)).serializable_hash
  end
end
