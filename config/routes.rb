Rails.application.routes.draw do
  if Rails.env.development?
    mount PgHero::Engine, at: "pghero"
  end
  resources :customers do
    get "/page/:page", action: :index, on: :collection
  end
  resources :sales do
    get "/page/:page", action: :index, on: :collection
  end
  resources :products do
    get "/page/:page", action: :index, on: :collection
  end
  resources :purchases do
    get "/page/:page", action: :index, on: :collection
  end
  resources :payments, only: [:create]

  scope "/admin" do
    resources :versions, :suppliers, :sizes, :franchises, :shapes, :colors, :brands
  end

  post "webhook-order", to: "webhook#order_to_sale"

  get "dashboard/index"
  get "debts", to: "dashboard#debts"

  root "dashboard#index"
end
