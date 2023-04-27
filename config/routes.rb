Rails.application.routes.draw do
  resources :addresses, only: [:show], param: :id
  resources :transactions, only: [:create]
end
