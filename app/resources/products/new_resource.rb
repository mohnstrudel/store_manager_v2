# frozen_string_literal: true

class Products::NewResource < Products::FormResource
  typelize({
    supplier_id: "number | null",
    order_reference: :string,
    item_price: :string,
    amount: :string,
    warehouse_id: "number | null",
    payment_value: :string,
    variant_client_key: "string | null"
  })
  attribute :purchase do |_page|
    {
      supplier_id: nil,
      order_reference: "",
      item_price: "",
      amount: "",
      warehouse_id: Warehouse.find_by(is_default: true)&.id,
      payment_value: "",
      variant_client_key: nil
    }
  end
end
