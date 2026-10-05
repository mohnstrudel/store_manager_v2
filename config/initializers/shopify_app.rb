# frozen_string_literal: true

ShopifyApp.configure do |config|
  config.api_version = "2026-07"
  config.scope = "read_products, write_products, read_orders, read_all_orders, read_order_edits, read_customers, read_inventory, write_images, read_files, write_files, read_payment_terms, read_locations"

  config.root_url = "/shopify_app"
  config.login_callback_url = "/shopify_app/auth/shopify/callback"
  config.login_url = "https://68d8f5-af.myshopify.com/"

  config.disable_webpacker = true
  config.application_name = "My Shopify App"
  config.old_secret = ""
  config.embedded_app = false
  config.new_embedded_auth_strategy = false

  config.after_authenticate_job = false
  config.shop_session_repository = "Shop"
  config.log_level = :info
  config.reauth_on_access_scope_changes = true

  config.webhook_jobs_namespace = "shopify/webhooks"
  config.webhooks = []

  config.api_key = ENV.fetch("SHOPIFY_API_KEY", "").presence
  config.secret = ENV.fetch("SHOPIFY_API_SECRET", "").presence

  if defined? Rails::Server
    raise("Missing SHOPIFY_API_KEY. See https://github.com/Shopify/shopify_app#requirements") unless config.api_key
    raise("Missing SHOPIFY_API_SECRET. See https://github.com/Shopify/shopify_app#requirements") unless config.secret
  end
end

Rails.application.config.after_initialize do
  if ShopifyApp.configuration.api_key.present? && ShopifyApp.configuration.secret.present?
    ShopifyAPI::Context.setup(
      api_key: ShopifyApp.configuration.api_key,
      api_secret_key: ShopifyApp.configuration.secret,
      api_version: ShopifyApp.configuration.api_version,
      host: ENV["HOST"],
      scope: ShopifyApp.configuration.scope,
      is_private: !ENV.fetch("SHOPIFY_APP_PRIVATE_SHOP", "").empty?,
      is_embedded: ShopifyApp.configuration.embedded_app,
      log_level: :info,
      logger: Rails.logger,
      private_shop: ENV.fetch("SHOPIFY_APP_PRIVATE_SHOP", nil),
      user_agent_prefix: "ShopifyApp/#{ShopifyApp::VERSION}"
    )

    ShopifyApp::WebhooksManager.add_registrations
  end
end
