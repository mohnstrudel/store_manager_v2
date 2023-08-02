Rails.application.routes.draw do
  resources :products
  scope "/admin" do
    resources :versions, :suppliers, :sizes, :franchises, :shapes, :colors, :brands
  end
  get "dashboard/index"
  root "dashboard#index"
end
