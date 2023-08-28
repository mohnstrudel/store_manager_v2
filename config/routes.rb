Rails.application.routes.draw do
  resources :purchases
  resources :payments, only: [:create]
  resources :products

  scope "/admin" do
    resources :versions, :suppliers, :sizes, :franchises, :shapes, :colors, :brands
  end

  get "dashboard/index"
  root "dashboard#index"
end
