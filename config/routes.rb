Rails.application.routes.draw do
  if Rails.env.production?
    mount MissionControl::Jobs::Engine, at: "/jobs"
  end

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
    get "gallery", action: :gallery, on: :member
  end

  resources :purchases do
    get "/page/:page", action: :index, on: :collection
  end

  resources :payments, only: [:create]

  scope "/admin" do
    resources :versions, :suppliers, :sizes, :franchises, :shapes, :colors, :brands
  end

  post "update-order", to: "webhook#update_sale"

  get "dashboard/index"

  get "debts", to: "dashboard#debts"
  get "debts/:page", to: "dashboard#debts"

  root "dashboard#index"
end
