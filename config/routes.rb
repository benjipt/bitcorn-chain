#config/routes.rb
Rails.application.routes.draw do
  resources :addresses, only: [:show, :create], param: :id
  resources :transactions, only: [:create]
end
