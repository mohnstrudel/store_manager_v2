# == Schema Information
#
# Table name: customers
#
#  id         :bigint           not null, primary key
#  first_name :string
#  last_name  :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  woo_id     :string
#
FactoryBot.define do
  factory :customer do
    woo_id { "MyString" }
    first_name { "MyString" }
    last_name { "MyString" }
  end
end
