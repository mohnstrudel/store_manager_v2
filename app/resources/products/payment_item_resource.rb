# frozen_string_literal: true

class Products::PaymentItemResource < Products::SoldItemResource
  typelize :string, nullable: true
  attribute :price do |sale_item|
    format_money(sale_item.price)
  end

  typelize :number, nullable: true
  attribute :sequence do |sale_item|
    follow_up_plan(sale_item.sale)&.part_number_for(sale_item.sale)
  end

  typelize :number, nullable: true
  attribute :expected_parts do |sale_item|
    follow_up_plan(sale_item.sale)&.expected_parts
  end

  typelize({path: :string, identifier: :string}, nullable: true)
  attribute :origin do |sale_item|
    origin(follow_up_plan(sale_item.sale), sale_item.sale)
  end

  def follow_up_plan(sale)
    sale.payment_plans.find { |plan| plan.origin_sale_id != sale.id && plan.part_number_for(sale).present? }
  end

  def origin(plan, sale)
    origin = plan&.origin_sale
    return if origin.nil? || origin.id == sale.id

    {path: sale_path(origin), identifier: origin.shop_identifier.presence || origin.id.to_s}
  end
end
