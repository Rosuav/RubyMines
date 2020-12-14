Rails.application.routes.draw do
	get "/game/:width/:height/:mines", to: "games#fetch"
	# For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html
end
