ActionController::Routing::Routes.draw do |map|
  #map.root :controller => "invoices" 
  map.invoices_totals 'invoices/totals.:format', :controller => 'invoices', :action => 'totals'
  map.account_sales_totals 'accounts/sales_totals.:format', :controller => 'accounts', :action => 'sales_totals'
  map.account_open_invoices_totals 'accounts/open_invoices_totals.:format', :controller => 'accounts', :action => 'open_invoices_totals'
  map.connect 'documents/:id/:filename.:extension', :controller => 'documents', :action => 'download', :conditions => { :method => :get }
  map.account_invoice_tags 'accounts/:id/invoice_tags', :controller => 'accounts', :action => 'invoice_tags'
  map.customer_invoices 'customers/:id/invoices', :controller => 'customers', :action => 'invoices'
  map.enable_user 'users/enable/:id', :controller => 'users', :action => 'enable'
  map.disable_user 'users/disable/:id', :controller => 'users', :action => 'disable'
  map.customer_search 'customers/search.:format', :controller => 'customers', :action => 'search'
  map.active_invoice 'invoices/active/:id', :controller => 'invoices', :action => 'active'
  map.cancel_invoice 'invoices/cancel/:id', :controller => 'invoices', :action => 'cancel'
  map.close_invoice 'invoices/close/:id', :controller => 'invoices', :action => 'close'
  map.search_invoice 'invoices/search', :controller => 'invoices', :action => 'search'
  map.edit_tags 'invoices/:id/update_tags', :controller => 'invoices', :action => 'update_tags'
  map.login 'login', :controller => 'user_sessions', :action => 'new'
  map.logout 'logout', :controller => 'user_sessions', :action => 'destroy'
  map.signup 'signup', :controller => 'accounts', :action => 'new'

  map.resource :dashboard, :only => [:index, :show]
  map.resources :password_resets, :conditions => {:subdomain => /.+/}
  map.resources :customers, :has_many => [:contacts, :invoices]
  map.resources :contacts, :except => [:index]
  map.resources :invoices, :has_many => [:comments]
  map.resources :accounts, :has_many => [:users, :invoices, :customers, :taxes]
  map.resources :comments
  map.resources :documents
  map.resources :taxes
  map.resources :banks
  map.resources :users, :except => [:show]
  map.resources :user_sessions
  map.application_root "/", :controller => "dashboards", :action => "show", :conditions => {:subdomain => /.+/}
  map.public_root "/", :controller => "public", :action => "index", :conditions => {:subdomain => nil}

  # The priority is based upon order of creation: first created -> highest priority.

  # Sample of regular route:
  #   map.connect 'products/:id', :controller => 'catalog', :action => 'view'
  # Keep in mind you can assign values other than :controller and :action

  # Sample of named route:
  #   map.purchase 'products/:id/purchase', :controller => 'catalog', :action => 'purchase'
  # This route can be invoked with purchase_url(:id => product.id)

  # Sample resource route (maps HTTP verbs to controller actions automatically):
  #   map.resources :products

  # Sample resource route with options:
  #   map.resources :products, :member => { :short => :get, :toggle => :post }, :collection => { :sold => :get }

  # Sample resource route with sub-resources:
  #   map.resources :products, :has_many => [ :comments, :sales ], :has_one => :seller
  
  # Sample resource route with more complex sub-resources
  #   map.resources :products do |products|
  #     products.resources :comments
  #     products.resources :sales, :collection => { :recent => :get }
  #   end

  # Sample resource route within a namespace:
  #   map.namespace :admin do |admin|
  #     # Directs /admin/products/* to Admin::ProductsController (app/controllers/admin/products_controller.rb)
  #     admin.resources :products
  #   end

  # You can have the root of your site routed with map.root -- just remember to delete public/index.html.
  # map.root :controller => "welcome"

  # See how all your routes lay out with "rake routes"

  # Install the default routes as the lowest priority.
  # Note: These default routes make all actions in every controller accessible via GET requests. You should
  # consider removing or commenting them out if you're using named routes and resources.
  #map.connect ':controller/:action/:id'
  #map.connect ':controller/:action/:id.:format'
end
