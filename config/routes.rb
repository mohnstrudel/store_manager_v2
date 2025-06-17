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

  resources :purchase_items
  resources :sale_items

  post "purchase_items/move", to: "purchase_items#move", as: :move_purchase_items

  post "purchase_items/unlink", to: "purchase_items#unlink", as: :unlink_purchase_item

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
      get :link_purchase_items
    end
  end

  resources :products do
    get "/page/:page", action: :index, on: :collection
    get "pull", action: :pull, on: :collection
    get "pull", action: :pull, on: :member
  end

  resources :purchases do
    collection do
      get "/page/:page", action: :index
      get "product_editions"
    end
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
