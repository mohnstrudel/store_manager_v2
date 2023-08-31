Rails.application.routes.draw do
  resources :products do
    get "/page/:page", action: :index, on: :collection
  end
  resources :purchases
  resources :payments, only: [:create]
  post "webhook-order", to: "webhook#create_order"

  scope "/admin" do
    resources :versions, :suppliers, :sizes, :franchises, :shapes, :colors, :brands
  end

  get "dashboard/index"
  root "dashboard#index"
end
