require "sidekiq/web"
require "sidekiq-status/web"

Rails.application.routes.draw do
  root "dashboard#index"

  # For monitoring db health
  if Rails.env.development?
    mount PgHero::Engine, at: "pghero"
  end

  # Shopify integration
  mount ShopifyApp::Engine, at: "shopify_app"
  mount Sidekiq::Web => "jobs"

  # WooCommerce integration
  post "update-order", to: "webhook#process_order"

  # Shopify sale status webhook
  post "sale-status", to: "webhook#sale_status"

  resources :passwords, param: :token

  resources :users, except: %i[new create]
  get "sign_up", to: "users#new", as: :new_sign_up
  post "sign_up", to: "users#create", as: :sign_up

  resource :session, except: %i[new destroy]
  get "sign_in", to: "sessions#new", as: :sign_in
  post "log_out", to: "sessions#destroy", as: :log_out

  get "debts", to: "dashboard#debts"
  get "debts/:page", to: "dashboard#debts"
  get "pull-last-orders", to: "dashboard#pull_last_orders"
  get "noop", to: "dashboard#noop", as: :noop

  resources :purchase_items do
    collection do
      post :move
      post :unlink
    end
    member do
      get :edit_tracking_number
      get :cancel_tracking_number
      patch :update_tracking_number
    end
  end

  resources :sale_items

  resources :products do
    collection do
      get "/page/:page", action: :index
      get :pull
    end
    get :pull, on: :member
  end

  resources :sales do
    collection do
      get :pull
      get "/page/:page", action: :index
    end
    member do
      get :pull
      get :link_purchase_items
    end
  end

  resources :purchases do
    collection do
      get "/page/:page", action: :index
      get :product_editions
      post :move
    end
  end

  resources :warehouses do
    member do
      get "/page/:page", action: :show
      post :change_position
    end
  end

  resources :customers do
    get "/page/:page", action: :index, on: :collection
  end

  resources :payments, only: [:create]

  resources :versions, :suppliers, :sizes, :franchises, :shapes, :colors, :brands, :shipping_companies
end
