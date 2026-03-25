# frozen_string_literal: true

require "sidekiq/web"
require "sidekiq-status/web"

Rails.application.routes.draw do
  # System
  get "up", to: "rails/health#show", as: :rails_health_chec
  root "dashboard#index"

  # Operations
  if Rails.env.development?
    mount PgHero::Engine, at: "pghero"
  end

  mount ShopifyApp::Engine, at: "shopify_app"
  mount Sidekiq::Web => "jobs"

  # External webhooks
  post "update-order", to: "webhooks/order_updates#create"
  post "sale-status", to: "webhooks/sale_statuses#create"

  # Authentication
  resources :passwords, param: :token

  resources :users, except: %i[new create]
  resource :sign_up, only: %i[new create], controller: :signups

  resource :session, except: %i[new destroy]
  get "sign_in", to: "sessions#new", as: :sign_in
  post "log_out", to: "sessions#destroy", as: :log_out

  # Dashboard
  get "debts", to: "dashboard/debts#show"
  get "debts/:page", to: "dashboard/debts#show"
  get "noop", to: "dashboard#noop", as: :noop

  scope module: :dashboard do
    resource :last_orders_pull, only: :create, path: "pull-last-orders"
  end

  # Inventory
  resources :products do
    scope module: :products do
      resource :shopify_pull, only: :create

      collection do
        resource :products_pull, only: :create, path: "pull", controller: :pulls
      end
    end

    collection do
      get "page/:page", action: :index
    end
  end

  resources :sales do
    scope module: :sales do
      resources :items, only: %i[show edit update destroy], controller: :items
      resource :purchase_item_link, only: :create, path: "link_purchase_items"
      resource :pull, only: :create

      collection do
        resource :sales_bulk_pull, only: :create, path: "pull", controller: :bulk_pulls
      end
    end

    collection do
      get "page/:page", action: :index
    end
  end

  resources :purchases do
    scope module: :purchases do
      resources :payments, only: :create

      collection do
        resource :move, only: :create
        resource :product_editions, only: :show
      end
    end

    collection do
      get "page/:page", action: :index
    end
  end

  resources :purchase_items, except: %i[new create] do
    scope module: :purchase_items do
      collection do
        resource :warehouse_move, only: :create, path: "move"
      end

      resource :sale_item_link, only: :destroy, path: "unlink"
      resource :tracking_number, only: %i[show edit update]
      resource :shipping_company, only: %i[show edit update]
    end
  end

  resources :warehouses, except: :show do
    scope module: :warehouses do
      resources :items, only: %i[new create], controller: :items
      resource :position, only: :update, path: "change_position"
    end
  end

  get "warehouses/:id", to: "warehouses/details#show"
  get "warehouses/:id/page/:page", to: "warehouses/details#show"

  resources :customers do
    collection do
      get "page/:page", action: :index
    end
  end

  # Reference data
  resources :versions, :suppliers, :sizes, :franchises, :shapes, :colors, :brands, :shipping_companies
end
