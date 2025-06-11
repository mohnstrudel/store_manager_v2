require "sidekiq/web"
require "sidekiq-status/web"

Rails.application.routes.draw do
  root "dashboard#index"
  get "shopify", to: "home#index"

  mount ShopifyApp::Engine, at: "/"
  mount Sidekiq::Web => "/jobs"

  if Rails.env.development?
    mount PgHero::Engine, at: "pghero"
  end

  resources :purchased_products
  resources :product_sales

  post "purchased_products/move", to: "purchased_products#move", as: :move_purchased_products

  post "purchased_products/unlink", to: "purchased_products#unlink", as: :unlink_purchased_product

  post "move_purchases", to: "purchases#move"

  resources :warehouses do
    get "/page/:page", action: :show, on: :member
    post :change_position, on: :member
  end

  resources :customers do
    get "/page/:page", action: :index, on: :collection
  end

  resources :sales do
    get "/page/:page", action: :index, on: :collection
    get "pull", action: :pull, on: :collection
    get "pull", action: :pull, on: :member
    member do
      get :link_purchased_products
    end
  end

  resources :products do
    get "/page/:page", action: :index, on: :collection
    get "editions", on: :member
    get "pull", action: :pull, on: :collection
    get "pull", action: :pull, on: :member
  end

  resources :purchases do
    get "/page/:page", action: :index, on: :collection
  end

  resources :payments, only: [:create]

  scope "/admin" do
    resources :versions, :suppliers, :sizes, :franchises, :shapes, :colors, :brands
  end

  post "update-order", to: "webhook#process_order"

  get "dashboard/index"

  get "debts", to: "dashboard#debts"
  get "debts/:page", to: "dashboard#debts"

  get "pull-last-orders", to: "dashboard#pull_last_orders"
end
