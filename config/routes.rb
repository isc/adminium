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
  resource :account, :only => [:edit, :update]
  resources :collaborators, :only => [:create, :destroy]

  namespace :heroku do
    resources :resources, :only => [:create, :destroy, :update, :show]
    resources :accounts, :only => [:update]
  end
  match 'sso/login' => 'heroku/resources#sso_login'
  match 'test/threads' => 'resources#test_threads'

  # Sample resource route with options:
  #   resources :products do
  #     member do
  #       get 'short'
  #       post 'toggle'
  #     end
  #
  #     collection do
  #       get 'sold'
  #     end
  #   end

  # Sample resource route with more complex sub-resources
  #   resources :products do
  #     resources :comments
  #     resources :sales do
  #       get 'recent', :on => :collection
  #     end
  #   end

  # Sample resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
  #   end

  # You can have the root of your site routed with "root"
  # just remember to delete public/index.html.
  root :to => 'docs#index'

end
