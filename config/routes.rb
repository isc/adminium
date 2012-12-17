Adminium::Application.routes.draw do

  match '/auth/:provider/callback' => 'sessions#create'
  match '/signout' => 'sessions#destroy', as: :signout

  resources :resources, path: "/resources/:table" do
    get 'page/:page', action: :index, on: :collection
    post :bulk_destroy, on: :collection
    post :bulk_update, on: :collection
    get :bulk_edit, on: :collection
  end

  resources :settings do
    get :values, on: :member
    get :columns, on: :collection
    post :update_advanced_search, on: :member
  end

  resources :widgets
  resources :searches

  resources :column_settings
  resource :general_settings, only: [:edit, :update]

  resources :docs, only: [:index, :show] do
    collection do
      get :start_demo
      get :stop_demo
    end
  end
  resource :sessions, only: [] do
    get :switch_account
  end
  resource :account, only: [:edit, :update] do
    get :db_url_presence, on: :member
  end
  resources :roles
  resource :dashboard
  resources :collaborators

  namespace :heroku do
    resources :resources, only: [:create, :destroy, :update, :show]
    resources :accounts, only: [:update]
  end
  match 'sso/login' => 'heroku/resources#sso_login'
  match 'test/threads' => 'resources#test_threads'

  root to: 'docs#homepage'

end
