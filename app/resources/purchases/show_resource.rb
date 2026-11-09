# frozen_string_literal: true

class Purchases::ShowResource < ApplicationResource
  typelize "PurchasesDetail"
  attribute :purchase do |page|
    Purchases::DetailResource.new(page.fetch(:purchase)).serializable_hash
  end

  typelize "Array<PurchasesPurchaseItem>"
  attribute :purchase_items do |page|
    Purchases::PurchaseItemResource.new(
      page.fetch(:purchase_items),
      params: {warehouses_by_id: warehouses.index_by(&:id)}
    ).serializable_hash
  end

  typelize "Array<PurchasesPayment>"
  attribute :payments do |page|
    Purchases::PaymentResource.new(page.fetch(:payments), params: {purchase: page.fetch(:purchase)}).serializable_hash
  end

  typelize({create_path: :string, payment_date: :string, value: :string})
  attribute :new_payment do |page|
    new_payment = page.fetch(:new_payment)

    {
      create_path: purchase_payments_path(page.fetch(:purchase)),
      payment_date: (new_payment.payment_date&.to_date || Time.zone.today).iso8601,
      value: decimal_field_value(new_payment.value)
    }
  end

  typelize "Array<WarehouseOption>"
  attribute :warehouses do |_page|
    WarehouseOptionResource.new(warehouses).serializable_hash
  end

  typelize :string
  attribute :warehouse_move_path do |_page|
    warehouse_move_path
  end

  typelize "Array<ShippingCompanyOption>"
  attribute :shipping_companies do |_page|
    ShippingCompanyOptionResource.new(ShippingCompany.ordered).serializable_hash
  end

  def warehouses
    @warehouses ||= Warehouse.order(name: :asc).to_a
  end
end
