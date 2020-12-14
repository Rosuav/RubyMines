class GamesController < ApplicationController
	def fetch
		game = Game.find_by(height:params[:height], width:params[:width], mines:params[:mines])
		# If there's no game matching that, this will return null. The front end should establish
		# a websocket to await an available game.
		if not game
			render json: nil
			return
		end
		game = game.as_json
		game["mines"] = []
		# TODO: Simplify this down. I just want to fetch all the [x,y] pairs for this game.
		# Note that these are really [r,c] not [x,y]. TODO: Learn migrations and fix these names.
		Mine.where(game_id: game["id"]).each do | mine | game["mines"].append([mine["x"], mine["y"]]) end
		# assert game["mines"].length == Integer(params[:mines])
		# TODO: Delete this game and its mines (not done in development b/c easier to not recreate)
		render json: game.to_json
	end
end
