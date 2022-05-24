Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Defines the root path route ("/")
  # root "articles#index"
  namespace :v1 do 
	resources :channels do
		resources :subscriptions do
			resources :messages do 
				member do
					put :complete
				end
			end
		end
		resources :cursors do 
			resources :messages do
				member do 
					put :complete 
				end
			end
		end
	end
  end
end
