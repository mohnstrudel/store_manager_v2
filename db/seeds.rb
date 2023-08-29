Size.create(value: "1:1")
Size.create(value: "1:2")
Size.create(value: "1:4")
Shape.create(title: "Bust")
Shape.create(title: "Statue")
Version.create(value: "Exclusive")
Version.create(value: "Regular")
Version.create(value: "Deluxe")
Version.create(value: "VIP")

10.times do
  Supplier.create(title: Faker::Company.name)
  Franchise.create(title: Faker::DcComics.title)
  Brand.create(title: Faker::App.name)
  Color.create(value: Faker::Color.color_name)
end

20.times do
  product = Product.create({
    title: Faker::DcComics.name,
    franchise: Franchise.order("RANDOM()").limit(1).first,
    shape: Shape.order("RANDOM()").limit(1).first
  })
  Supplier.order("RANDOM()").limit(5).each do |supplier|
    product.suppliers << supplier
  end
  Size.order("RANDOM()").limit(3).each do |size|
    product.sizes << size
  end
  Brand.order("RANDOM()").limit(3).each do |brand|
    product.brands << brand
  end
  Version.order("RANDOM()").limit(4).each do |version|
    product.versions << version
  end
  Color.order("RANDOM()").limit(rand(1..5)).each do |color|
    product.colors << color
  end
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
  5..10.times do
    purchase.payments.create({
      value: Faker::Number.decimal(l_digits: 3, r_digits: 2),
      purchase_id: purchase.id
    })
  end
end
