Size.create(value: "1:1")
Size.create(value: "1:2")
Size.create(value: "1:4")
Shape.create(title: "Bust")
Shape.create(title: "Statue")
Version.create(value: "Regular")
Version.create(value: "Oversize")
Version.create(value: "Slim")
Version.create(value: "Skinny")

10.times do
  Supplier.create(title: Faker::Company.name)
  Franchise.create(title: Faker::DcComics.title)
  Brand.create(title: Faker::App.name)
  Color.create(value: Faker::Color.color_name)
end

20.times do
  Product.create({
    title: Faker::DcComics.name,
    supplier: Supplier.order("RANDOM()").limit(1).first,
    franchise: Franchise.order("RANDOM()").limit(1).first,
    brand: Brand.order("RANDOM()").limit(1).first,
    color: Color.order("RANDOM()").limit(1).first,
    size: Size.order("RANDOM()").limit(1).first,
    shape: Shape.order("RANDOM()").limit(1).first,
    version: Version.order("RANDOM()").limit(1).first
  })
end

10.times do
  Purchase.create({
    amount: Faker::Number.number(digits: 2),
    order_reference: Faker::IDNumber.spanish_foreign_citizen_number,
    item_price: Faker::Number.decimal(l_digits: 3, r_digits: 2),
    product: Product.order("RANDOM()").limit(1).first,
    supplier: Supplier.order("RANDOM()").limit(1).first
  })
end

Purchase.all.each do |purchase|
  3.times do
    purchase.payments.create({
      value: Faker::Number.decimal(l_digits: 3, r_digits: 2),
      purchase_id: purchase.id
    })
  end
end
