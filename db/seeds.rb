STATUSES = ["processing", "shipping", "partially-paid", "cancelled", "paid"]

10.times do
  Supplier.create(title: Faker::Company.name)
end

10.times do
  Purchase.create({
    amount: Faker::Number.number(digits: 2),
    order_reference: Faker::IDNumber.spanish_foreign_citizen_number,
    item_price: Sale.order("RANDOM()").limit(1).first.total,
    product: Product.order("RANDOM()").limit(1).first,
    supplier: Supplier.order("RANDOM()").limit(1).first
  })
end

Purchase.all.each do |purchase|
  payments_qty = rand(5..10)
  payment_amount = purchase.total_price / (payments_qty + rand(5))
  payments_qty.times do
    purchase.payments.create({
      value: payment_amount,
      purchase_id: purchase.id
    })
  end
end

Purchase.first.payments.each(&:destroy)
Purchase.last.payments.each(&:destroy)
