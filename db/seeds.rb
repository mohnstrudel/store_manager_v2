STATUSES = ["processing", "shipping", "partially-paid", "cancelled", "paid"]

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
  Customer.create(
    first_name: Faker::Name.first_name,
    last_name: Faker::Name.last_name,
    woo_id: Faker::IDNumber.spanish_foreign_citizen_number,
    phone: Faker::PhoneNumber.cell_phone,
    email: Faker::Internet.email
  )
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
  rand(5..10).times do
    purchase.payments.create({
      value: Faker::Number.decimal(l_digits: 3, r_digits: 2),
      purchase_id: purchase.id
    })
  end
end

40.times do
  shipping_total = Faker::Number.decimal(l_digits: 2, r_digits: 2)
  discount_total = Faker::Number.decimal(l_digits: 2, r_digits: 2)
  total = Faker::Number.decimal(l_digits: 2, r_digits: 2) + shipping_total
  qty = Faker::Number.number(digits: 2)
  item_price = total / qty
  sale = Sale.create({
    address_1: Faker::Address.street_address,
    address_2: Faker::Address.secondary_address,
    city: Faker::Address.city,
    company: Faker::Company.name,
    country: Faker::Address.country,
    discount_total: discount_total,
    note: Faker::Lorem.paragraph,
    postcode: Faker::Address.postcode,
    shipping_total: shipping_total,
    state: Faker::Address.state,
    status: STATUSES[Random.rand(STATUSES.length)],
    total: total,
    woo_id: Faker::IDNumber.spanish_foreign_citizen_number,
    customer: Customer.order("RANDOM()").limit(1).first
  })
  rand(1..5).times do
    ProductSale.create({
      price: item_price,
      qty: qty,
      product: Product.order("RANDOM()").limit(1).first,
      sale: sale
    })
  end
end
