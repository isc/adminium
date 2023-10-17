Rails.application.routes.draw do
  get '/ping' => 'ping#ping'
  get '/install' => 'docs#install'
  get '/signout' => 'sessions#destroy', as: :signout
  
  resources :resources, path: '/resources/:table', constraints: {id: /.*/} do
    collection do
      get 'page/:page', action: :index
      post :bulk_destroy
      post :bulk_update
      get :bulk_edit
      get :import
      post :check_existence
      post :perform_import
      get :search
      get :chart
    end
    get :download, on: :member
  end
  resources :settings do
    get :values, on: :member
    get :columns, on: :collection
    post :update_advanced_search, on: :member
  end
  resources :widgets, only: %i(create update destroy)
  resources :schemas
  resources :searches
  resources :column_settings
  resources :docs, only: :index do
    get :keyboard_shortcuts, on: :collection
  end
  resource :install do
    get :setup_database_connection
  end
  resource :session, only: %i(new create destroy) do
    post :callback
    get :switch_account
  end
  resource :user, only: :show
  resource :registration, only: %i(new create) do
    post :callback
  end
  resource :account, only: %i(new create edit update) do
    post :cancel_tips, on: :member
  end
  resources :roles, except: %i(show)
  resource :dashboard, only: :show do
    get :settings
    get :bloat
  end
  resources :collaborators
  root to: 'docs#landing'
end
