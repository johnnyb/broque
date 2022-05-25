Rails.application.routes.draw do
	# Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

	# Defines the root path route ("/")
	# root "articles#index"

	get "/maintenance/periodic_maintenance", :to => "maintenance#periodic_maintenance"

	namespace :v1 do 
		resources :channels do
			resources :messages 
			
			resources :subscriptions do
				member do
					put :reset
				end
				resources :messages do 
					member do
						put :complete
					end
					collection do
						get :dead
						put "dead/clear", :action => "clear_dlq"
						put "dead/redrive", :action => "redrive_dlq"
					end
				end
			end
			resources :cursors do 
				member do 
					put :reset
				end
				resources :messages do
					member do 
						put :complete 
					end
					collection do
						get :dead
						put "dead/clear", :action => "clear_dlq"
						put "dead/redrive", :action => "redrive_dlq"
					end
				end
			end
		end
	end
end
