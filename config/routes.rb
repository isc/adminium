MtCrap::Application.routes.draw do
  
  match '/auth/:provider/callback' => 'sessions#create'
  match '/signout' => 'sessions#destroy', :as => :signout

  resources :resources, :path => "/resources/:table" do
    get 'page/:page', :action => :index, :on => :collection
  end

  resources :settings do
    get :values, :on => :member
  end
  resource :general_settings, :only => [:edit, :update]

  resources :docs, :only => [:index, :show]
  resource :sessions, :only => [] do
    get :switch_account
  end
  resource :account, :only => [:edit, :update]
  resource :dashboard
  resources :collaborators, :only => [:create, :destroy]

  namespace :heroku do
    resources :resources, :only => [:create, :destroy, :update, :show]
    resources :accounts, :only => [:update]
  end
  match 'sso/login' => 'heroku/resources#sso_login'
  match 'test/threads' => 'resources#test_threads'

  root :to => 'dashboards#show'

end
