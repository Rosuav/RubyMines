class GamesController < ApplicationController
	def fetch
		game = Game.find_by(height:params[:height], width:params[:width], mines:params[:mines])
		# If there's no game matching that, this will return null. The front end should establish
		# a websocket to await an available game.
		if not game
			# TODO: Add it to Requests if not already there
			render json: nil # Signal the front end that we don't (yet) have a game
			return
		end
		game = game.as_json
		game["mines"] = []
		# TODO: Simplify this down. I just want to fetch all the [x,y] pairs for this game.
		# Note that these are really [r,c] not [x,y]. TODO: Learn migrations and fix these names.
		Mine.where(game_id: game["id"]).each do | mine | game["mines"].append([mine["x"], mine["y"]]) end
		# assert game["mines"].length == Integer(params[:mines])
		ActiveRecord::Base.transaction {
			Mine.where(game_id: game["id"]).delete_all
			Game.where(id: game["id"]).delete_all
		}
		render json: game.to_json
	end
end
