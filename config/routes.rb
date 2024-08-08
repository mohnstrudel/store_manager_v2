require "sidekiq/web"

Rails.application.routes.draw do
  mount Sidekiq::Web => "/jobs"

  if Rails.env.development?
    mount PgHero::Engine, at: "pghero"
  end

  resources :purchased_products

  resources :warehouses do
    get "/page/:page", action: :show, on: :member
  end

  resources :customers do
    get "/page/:page", action: :index, on: :collection
  end

  resources :sales do
    get "/page/:page", action: :index, on: :collection
  end

  resources :products do
    get "/page/:page", action: :index, on: :collection
    get "variations", on: :member
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

  root "dashboard#index"
end
