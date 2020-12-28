module ApplicationCable
	class Connection < ActionCable::Connection::Base
		def connect
			# Can I disable the heartbeat messages??
			puts "Got websocket connection\n"
			@waiting = []
		end
		def receive(message)
			message = JSON.parse(message)
			puts "Got message from client\n"
			puts message
			puts "\n"
			if message["type"] == "wait" then
				$clients_waiting = {} unless $clients_waiting
				key = [message["height"], message["width"], message["mines"]]
				$clients_waiting[key] = [] unless $clients_waiting[key]
				@waiting.append(key)
				$clients_waiting[key].append(self)
				transmit type: "waiting"
			end
		end
		def disconnect
			puts "Websocket gone\n"
			for key in @waiting do
				$clients_waiting[key].delete(self)
			end
		end
	end
end
