require 'rake'

class GamesController < ApplicationController
	def fetch
		game = Game.find_by(height:params[:height], width:params[:width], mines:params[:mines])
		# If there's no game matching that, this will return null. The front end should establish
		# a websocket to await an available game.
		if not game
			Request.create(height:params[:height], width:params[:width], mines:params[:mines])
			if $generate_thread and $generate_thread.alive?
				puts "Have thread"
			else
				puts "Didn't have thread"
				# TODO: Spin this off as a separate process - maybe a Heroku task when
				# on prod - as this is CPU-bound and causes problems.
				$generate_thread = Thread.new { load File.join(Rails.root, 'lib', 'tasks', 'generate_games.rb') }
			end
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
