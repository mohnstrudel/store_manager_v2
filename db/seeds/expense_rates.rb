# Starter business expense rates: the classic cost buckets a small commerce
# business pays as a share of revenue. Skipped entirely once the owner has
# touched the table, so deleted or edited rates never come back.
return if ExpenseRate.exists?

expense_rates = [
  {name: "Payroll", rate_percent: 15},
  {name: "Advertising & Marketing", rate_percent: 7},
  {name: "Rent", rate_percent: 5},
  {name: "Software & Admin", rate_percent: 5},
  {name: "Warehouse & Fulfillment", rate_percent: 4},
  {name: "Payment Processing Fees", rate_percent: 3}
]

expense_rates.each do |attrs|
  ExpenseRate.create!(name: attrs[:name], rate_percent: attrs[:rate_percent])
end
