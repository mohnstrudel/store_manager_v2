Rails.application.routes.draw do
  resources :sales do
    get "/page/:page", action: :index, on: :collection
  end
  resources :products do
    get "/page/:page", action: :index, on: :collection
  end
  resources :purchases
  resources :payments, only: [:create]

  scope "/admin" do
    resources :versions, :suppliers, :sizes, :franchises, :shapes, :colors, :brands
  end

  post "webhook-order", to: "webhook#create_order"
  get "dashboard/index"

  root "dashboard#index"
end
