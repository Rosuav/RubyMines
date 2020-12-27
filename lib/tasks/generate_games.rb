def generate_game(height, width, mines)
	game = Array.new(height) {[0] * width}
	mines_placed = []
	for m in 1..mines do
		r, c = rand(height), rand(width)
		redo if game[r][c] == 9 # We won't retry too many times - there can't be THAT many mines
		redo if r < 2 && c < 2 # Guarantee empty top-left cell as starter
		game[r][c] = 9
		mines_placed.append [r, c]
		for dr in -1..1 do for dc in -1..1 do
			next if r+dr < 0 || r+dr >= height || c+dc < 0 || c+dc >= width
			game[r+dr][c+dc] += 1 if game[r+dr][c+dc] != 9
		end; end
	end
	return game, mines_placed
end


# Returns an array of the cells dug. This can be empty (if the cell was not
# unknown), just the given cell (if it was unknown and had mines nearby), or
# a full array of many cells (if that cell had been empty).
def dig(game, r, c, dug=[])
	num = game[r][c]
	return dug if num > 9 # Already dug/flagged
	return dug if num == 9 # Boom! (You should die, but the autosolver shouldn't ever hit this.)
	game[r][c] += 10
	dug.append([r, c])
	if !num then # Dig around an empty spot
		for dr in -1..1 do for dc in -1..1 do
			next if r+dr < 0 || r+dr >= game.length || c+dc < 0 || c+dc >= game[0].length
			dig(game, r+dr, c+dc, dug)
		end; end
	end
	return dug
end

def flag(game, r, c)
	num = game[r][c]
	return false if num > 9 # Already dug/flagged
	return false if num < 9 # Not a mine (again, you should die)
	game[r][c] = 19
	return true;
end

def get_unknowns(game, r, c)
	# Helper for try_solve - get an array of the unknown cells around a cell
	# Returns [n, [r,c], [r,c], [r,c]] with any number of row/col pairs
	return nil if game[r][c] < 10 # Shouldn't happen
	ret = [game[r][c] - 10]
	for dr in -1..1 do for dc in -1..1 do
		next if r+dr < 0 || r+dr >= game.length || c+dc < 0 || c+dc >= game[0].length
		cell = game[r+dr][c+dc]
		ret.append([r+dr, c+dc]) if cell < 10
		ret[0] -= 1 if cell === 19
	end; end
	return ret
end

# Try to solve the game. Duh :)
# Algorithm is pretty simple. Build an array of regions, where a "region" is some
# group of unknown cells with a known number of mines among them. The initial set
# of regions comes from the dug cells - if the cell says "2" and it has three
# unknown cells adjacent to it and no flagged mines, we have a "two mines in three
# cells" region. Any region with no mines in it, or as many mines as cells, can be
# dug/flagged immediately. Then, proceed to subtract regions from regions: if one
# region is a strict subset of another, the difference is itself a region. So if
# two of the cells are also in a region of one mine, then the one cell NOT in the
# smaller region must have a mine in it. (The algorithm is simpler than it sounds.)
# Note that the *entire board* also counts as a region. This ensures that the
# search will correctly recognize iced-in sections as unsolveable, unless there are
# exactly the right number of mines for the section.
# TODO: Also handle overlaps between regions. Not every overlap yields new regions;
# it's only of value if you can divide the space into three parts: [ x ( x+y ] y )
# where the number of mines in regions X and Y are such that the *only* number of
# mines that can be in the x+y overlap would leave the x-only as all mines and the
# y-only as all clear. Look for these only if it seems that the game is unsolvable.
def try_solve(game, totmines)
	# First, build up a list of trivial regions.
	# One big region for the whole board:
	regions = [[totmines]]
	for r in 0...game.length do for c in 0...game[0].length do
		regions[0][0] -= 1 if game[r][c] === 19
		regions[0].append([r, c]) if game[r][c] < 10
	end; end
	# And then a region for every cell we know about.
	new_region = nil # Predeclare the new_region lambda?? I think this is necessary?
	base_region = -> (r, c) do
		return if game[r][c] < 10 || game[r][c] == 19
		region = get_unknowns(game, r, c)
		return if region.length == 1 # No unknowns
		new_region.call(region)
	end
	new_region = -> (region) do
		if region[0] == 0 then
			# There are no unflagged mines in this region!
			for rc in region[1..-1] do
				# Dig everything. Whatever we dug, add as a region.
				for dug in dig(game, rc[0], rc[1]) do
					base_region.call(dug[0], dug[1])
				end
			end
		elsif region[0] == region.length - 1 then
			# There are as many unflagged mines as unknowns!
			for rc in region[1..-1] do
				flag(game, rc[0], rc[1]);
			end
		else
			regions.append(region)
		end
	end
	for r in 0...game.length do for c in 0...game[0].length do
		base_region.call(r, c)
	end; end
	# Next, try to find regions that are strict subsets of other regions.
	found = true
	while found do
		found = false
		for r1 in regions do
			# TODO: Don't do this quadratically. Recognize which MIGHT be subsets.
			r1set = r1[1..-1].to_set
			for r2 in regions do
				next if r2.length <= 1
				r2set = r2[1..-1].to_set
				next unless r2set < r1set
				newreg = (r1set - r2set).to_a
				newreg.insert(0, r1[0] - r2[0])
				r1.slice!(0, r1.length) # Wipe the old region - we won't need it any more
				new_region.call(newreg);
				found = true
				break # No point scanning other r1 pairings
			end
		end
		# Prune the region list. Any that have been wiped go; others get their
		# cell lists pruned to those still unknown.
		scanme, regions = regions, []
		for region in scanme do
			for i in 1...region.length do
				break if i >= region.length # if we shorten the array, stop short
				cell = game[region[i][0]][region[i][1]]
				next if cell < 10
				region.slice!(i);
				region[0] -= 1 if cell == 19
				found = true # Changes were made.
			end
			new_region.call(region) if region.length > 1 # Might end up being all-clear or all-mines, or a new actual region
		end
	end
	return regions.length == 0
end

while true
	needed = ActiveRecord::Base.connection.execute('
		select requests.height, requests.width, requests.mines, count(games.id) as avail from requests left join games on
		requests.height = games.height and requests.width = games.width and requests.mines = games.mines
		group by requests.height, requests.width, requests.mines
		having count(games.id) < 3')
	makeme = needed.values.sample
	break unless makeme
	height, width, mines = makeme
	# if mines * 4 > height * width: remove this entry from requests and bail
	# shouldn't happen, guard in the web server
	print("Generating ", height, "x", width, " with ", mines, " mines\n")
	for try in 1..10000 do
		game, mines_placed = generate_game(height, width, mines)
		dig(game, 0, 0);
		break if try_solve(game, mines)
	end
	# TODO: Make sure we actually DID get a game. If we gave up... what?
	# Cool! We got a game. Save it to the database.
	print("Got a game in ", try, " tries\n")
	ActiveRecord::Base.transaction {
		g = Game.create(height:height, width:width, mines:mines)
		# TODO: As per elsewhere, rename this to r,c instead of x,y
		Mine.insert_all(mines_placed.map { |rc| ({game_id: g.id, x: rc[0], y: rc[1]}) } )
	}
	print("Saved!\n")
end
