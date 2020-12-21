def generate_game(height, width, mines)
	game = Array.new(height) {[0] * width}
	for m in 1..mines do
		r, c = rand(height), rand(width)
		redo if game[r][c] == 9 # We won't retry too many times - there can't be THAT many mines
		redo if r < 2 && c < 2 # Guarantee empty top-left cell as starter
		game[r][c] = 9
		for dr in -1..1 do for dc in -1..1 do
			next if r+dr < 0 || r+dr >= height || c+dc < 0 || c+dc >= width
			game[r+dr][c+dc] += 1 if game[r+dr][c+dc] != 9
		end; end
	end
	return game
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
	print(generate_game(height, width, mines))
	break
end
