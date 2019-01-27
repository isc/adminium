Rails.application.routes.draw do
  get '/ping' => 'ping#ping'
  get '/auth/heroku/callback' => 'sessions#create_from_heroku'
  get '/install' => 'docs#install'
  post '/auth/:provider/callback' => 'sessions#create'
  get '/auth/:provider/callback' => 'sessions#create'
  get '/signout' => 'sessions#destroy', as: :signout
  get '/sessions/login_heroku_app' => 'sessions#login_heroku_app', as: :login_heroku_app

  scope ':account_name' do
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
    resources :schemas, :searches, :collaborators, :column_settings, :collaborators
    resources :roles, except: %i(index show)
    resource :dashboard, only: :show do
      get :settings
      get :bloat
    end
  end
  resources :docs, only: :index do
    collection do
      get :start_demo
      get :stop_demo
      get :keyboard_shortcuts
    end
  end
  resource :install do
    get :invite_team
    get :setup_database_connection
    post :send_email_team
  end
  resource :account, only: %i(create edit update) do
    get :db_url_presence, on: :member
    get :update_db_url_from_heroku_api, on: :collection
    post :cancel_tips, on: :member
    get :upgrade
  end
  resource :user, only: :show do
    get :apps
  end
  namespace :heroku do
    resources :resources, only: %i(create destroy update show)
    resources :accounts, only: :update
  end
  post 'sso/login' => 'heroku/resources#sso_login'
  get 'test/threads' => 'resources#test_threads'
  get '/.well-known/acme-challenge/:id' => 'docs#letsencrypt'
  root to: 'docs#landing'
end
