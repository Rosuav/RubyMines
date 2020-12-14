class GamesController < ApplicationController
	def fetch
		game = Game.find_by(width:params[:width], height:params[:height], mines:params[:mines])
		# If there's no game matching that, this will return null. The front end should establish
		# a websocket to await an available game.
		if not game
			render json: nil
			return
		end
		render json: game.to_json
	end
end
