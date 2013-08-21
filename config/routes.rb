Adminium::Application.routes.draw do

  match '/auth/heroku/callback' => 'sessions#create_from_heroku'
  match '/auth/:provider/callback' => 'sessions#create'
  match '/signout' => 'sessions#destroy', as: :signout

  resources :resources, path: "/resources/:table", constraints: {id: /.*/} do
    collection do
      get 'page/:page', action: :index
      post :bulk_destroy
      post :bulk_update
      get :bulk_edit
      get :import
      post :check_existence
      post :perform_import
      get :search
      get :time_chart
    end
  end

  resources :settings do
    get :values, on: :member
    get :columns, on: :collection
    post :update_advanced_search, on: :member
  end

  resources :widgets

  resources :schemas

  resources :searches

  resources :column_settings
  resource :general_settings, only: [:edit, :update]

  resources :docs, only: [:index, :show] do
    collection do
      get :start_demo
      get :stop_demo
      get :missing_db_url
    end
  end
  resource :sessions, only: [] do
    get :switch_account
    get :login_heroku_app
  end
  resource :account, only: [:create, :edit, :update] do
    get :db_url_presence, on: :member
    get :update_db_url_from_heroku_api, on: :collection
    post :cancel_tips, on: :member
  end
  resources :roles
  resource :dashboard do
    get :tables_count, on: :collection
  end
  resources :collaborators
  resource :user

  namespace :heroku do
    resources :resources, only: [:create, :destroy, :update, :show]
    resources :accounts, only: [:update]
  end
  match 'sso/login' => 'heroku/resources#sso_login'
  match 'test/threads' => 'resources#test_threads'
  match 'landing' => 'docs#landing'
  match "test/:app_id" => 'accounts#create'
  root to: 'docs#homepage'

end
