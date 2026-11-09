Rails.application.routes.draw do
  root "trips#index"

  resources :trips, only: %i[index show new create] do
    # Fill in the new-trip form from a pasted group-chat message
    post :draft, on: :collection
    # Start (or reopen) a chat with this trip's rider
    resource :conversation, only: :create
    # Drop this rider from your matches and end any chat (both ways)
    resource :unmatch, only: :create
  end

  resources :conversations, only: %i[index show] do
    resources :messages, only: %i[create destroy]
    patch :report, on: :member
  end

  # The private link riders use to manage their own trip; the token is the key.
  get "manage/:token", to: "trips#edit", as: :manage_trip
  patch "manage/:token", to: "trips#update"
  delete "manage/:token", to: "trips#destroy"

  get "up" => "rails/health#show", as: :rails_health_check
end
