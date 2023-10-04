Rails.application.routes.draw do
  get '/ping' => 'ping#ping'
  get '/install' => 'docs#install'
  post '/auth/:provider/callback' => 'sessions#create'
  get '/auth/:provider/callback' => 'sessions#create'
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
    collection do
      get :start_demo
      get :stop_demo
      get :keyboard_shortcuts
    end
  end
  resource :install do
    get :setup_database_connection
  end
  resource :sessions, only: [] do
    get :switch_account
  end
  resource :account, only: %i(create edit update) do
    get :db_url_presence, on: :member
    post :cancel_tips, on: :member
  end
  resources :roles, except: %i(show)
  resource :dashboard, only: :show do
    get :settings
    get :bloat
  end
  resources :collaborators
  resource :user, only: :show do
    get :apps
  end
  post 'sso/login' => 'heroku/resources#sso_login'
  get 'test/threads' => 'resources#test_threads'
  get '/.well-known/acme-challenge/:id' => 'docs#letsencrypt'
  root to: 'docs#landing'
end
