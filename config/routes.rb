Rails.application.routes.draw do
  resources :products
  resources :versions
  resources :suppliers
  resources :sizes
  resources :franchises
  resources :shapes
  resources :colors
  resources :brands
  get 'dashboard/index'
  root 'dashboard#index'
end
