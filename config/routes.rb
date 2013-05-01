Adminium::Application.routes.draw do

  match '/auth/:provider/callback' => 'sessions#create'
  match '/signout' => 'sessions#destroy', as: :signout

  resources :resources, path: "/resources/:table" do
    collection do
      get 'page/:page', action: :index
      post :bulk_destroy
      post :bulk_update
      get :bulk_edit
      get :import
      get :check_existence
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

  resources :schemas, only: [:show]

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
  end
  resource :account, only: [:edit, :update] do
    get :db_url_presence, on: :member
    post :cancel_tips, on: :member
  end
  resources :roles
  resource :dashboard do
    get :tables_count, on: :collection
  end
  resources :collaborators

  namespace :heroku do
    resources :resources, only: [:create, :destroy, :update, :show]
    resources :accounts, only: [:update]
  end
  match 'sso/login' => 'heroku/resources#sso_login'
  match 'test/threads' => 'resources#test_threads'

  root to: 'docs#homepage'

end
