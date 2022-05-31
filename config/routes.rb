Rails.application.routes.draw do
	# Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

	# Defines the root path route ("/")
	# root "articles#index"

	get "/maintenance/periodic_maintenance", :to => "maintenance#periodic_maintenance"

	namespace :v1 do 
		resources :permissions
		resources :channels do
			resources :permissions

			resources :messages do
				collection do
					get :search 
				end
			end
			
			resources :subscriptions do
				member do
					put :reset
				end

				resources :permissions

				resources :messages do 
					member do
						put :complete
					end
					
					collection do
						put "receive", :action => "index"
						get :pending_count
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

				resources :permissions

				resources :messages do
					member do 
						put :complete 
					end

					collection do
						put "receive", :action => "index"
						get :pending_count
						get :dead
						put "dead/clear", :action => "clear_dlq"
						put "dead/redrive", :action => "redrive_dlq"
					end
				end
			end
		end
	end
end
