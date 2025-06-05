# == Schema Information
#
# Table name: shops
#
#  id             :bigint           not null, primary key
#  access_scopes  :string
#  shopify_domain :string           not null
#  shopify_token  :string           not null
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#
class Shop < ApplicationRecord
  include ShopifyApp::ShopSessionStorageWithScopes

  def api_version
    ShopifyApp.configuration.api_version
  end
end
