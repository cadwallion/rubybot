class WeatherModule
	def self.convert_to_c(value)
		if value =~ /^[\-0-9]*$/
			( value.to_i - 32 ) * 5 / 9
		else
			"N/A"
		end
	end
	def self.get_current(citycode, event, force=false)
		begin
			current_cached = event.connection.setup.memcache.get("current_"+citycode)
			if current_cached.nil? or force != false
				output = nil
				url = URI.parse("http://xoap.weather.com/weather/local/#{CGI.escape(citycode)}?cc=*&link=xoap&prod=xoap&par=#{event.connection.setup.config['weather_par']}&key=#{event.connection.setup.config['weather_api']}").to_s
				xmldoc = RemoteRequest.new("get").read(url)
				weather = (REXML::Document.new xmldoc).root
				if weather.elements['/weather/cc'] then
					current = "Location: #{weather.elements['/weather/loc/dnam'].text} - Updated at: #{weather.elements['/weather/cc/lsup'].text} - Temp: #{weather.elements['/weather/cc/tmp'].text}F (#{convert_to_c(weather.elements['/weather/cc/tmp'].text)}C) - Feels like: #{weather.elements['/weather/cc/flik'].text}F (#{convert_to_c(weather.elements['/weather/cc/flik'].text)}C) - Wind: #{weather.elements['/weather/cc/wind/t'].text} #{weather.elements['/weather/cc/wind/s'].text} MPH - Conditions: #{weather.elements['/weather/cc/t'].text} - Humidity: #{weather.elements['/weather/cc/hmid'].text}%"
					event.connection.setup.memcache.set("current_"+citycode, current, 30*60)
					current
				else
					current = "City code not found."
					event.connection.setup.memcache.set("current_"+citycode, current, 30*60)
					current
				end
			else
				current_cached + " (Cached)"
			end
		rescue URI::InvalidURIError
			"Could not parse URL"
		rescue => err
			log_error(err)
			"Error retrieving weather."
		end
	end
	def self.get_forecast(citycode, event, force=false)
		begin
			forecast_cached = event.connection.setup.memcache.get("forecast_"+citycode)
			if forecast_cached.nil? or force != false
				output = nil
				forecast = nil
				url = URI.parse("http://xoap.weather.com/weather/local/#{CGI.escape(citycode)}?cc=*&link=xoap&dayf=5&prod=xoap&par=#{event.connection.setup.config['weather_par']}&key=#{event.connection.setup.config['weather_api']}").to_s
				xmldoc = RemoteRequest.new("get").read(url)
					weather = (REXML::Document.new xmldoc).root
					if weather.elements['/weather/dayf'] then
						forecast = "Location: #{weather.elements['/weather/loc/dnam'].text}"
						weather.elements.each('/weather/dayf/day') do |day|
							forecast = forecast + " | #{day.attributes["t"]} #{day.attributes["dt"]} - High: #{day.elements['hi'].text}F (#{convert_to_c(day.elements['hi'].text)}C) - Low: #{day.elements['low'].text}F (#{convert_to_c(day.elements['low'].text)}C)"
							day.elements.each('part') do |part|
								if part.attributes["p"] == "n"
									forecast = forecast + " - Night: #{part.elements['t'].text}"
								else
									forecast = forecast + " - Day: #{part.elements['t'].text}"
								end
							end
						end
						event.connection.setup.memcache.set("forecast_"+citycode, forecast, 30*60) 
						forecast
					else
						forecast = "City code not found."
						event.connection.setup.memcache.set("forecast_"+citycode, forecast, 2*60*60) 
						forecast
					end
			else
				forecast_cached + " (Cached)"
			end
		rescue URI::InvalidURIError
			"Could not parse URL"
		rescue => err
			log_error(err)
			"Error retrieving weather."
		end
	end
	def self.search(citycode, event)
		begin
			locations = nil
			output = nil
			url = URI.parse("http://xoap.weather.com/search/search?where=#{CGI.escape(citycode)}").to_s
			xmldoc = RemoteRequest.new("get").read(url)
				weather = (REXML::Document.new xmldoc).root
				if weather.elements['/search/loc'] then
					weather.elements.each('/search/loc') do |location|
						if locations.nil?
							locations = "#{location.text} (#{location.attributes["id"]})"
						else
							locations = locations + ", #{location.text} (#{location.attributes["id"]})"
						end
					end
					locations
				else
					"City not found."
			end
		rescue URI::InvalidURIError
			"Could not parse URL"
		rescue => err
			log_error(err)
			"Error retrieving weather"
		end
	end

	def self.weather_reset(args, event)
		if user = UserModule.get_user(event)
			if user.update_attributes('location' => nil)
				return "Reset location"
			end
		end
		return false
	end
	def self.weather_search(args, event)
		return search(args, event)
	end
	def self.weather_convert(args, event)
		temp_c = convert_to_c(args)
		return "#{args.to_s}F is #{temp_c.to_s}C"
	end
	def self.weather_report(args, event)
		args = args.split
		users = UserModule.get_users(event)
		users.each do |user|
			unless args.size == 0 and (user.nil? or user.location.nil?)
				if args[0] == "force" and not user.location.nil?
					return get_current(user.location, event, true)
				elsif args.size > 1
					return get_current(args[0], event, true)
				elsif args.size == 1
					return get_current(args[0], event)
				else
					return get_current(user.location, event)
				end
			end
		end
		if users.nil? or users.size == 0
			if args.size > 1
				return get_current(args[0], event, true)
			elsif args.size == 1
				return get_current(args[0], event)
			end
		end
		return "City code or zip code is required or city information must be saved."
	end
	def self.weather_forecast(args, event)
		args = args.split
		users = UserModule.get_users(event)
		users.each do |user|
			unless args.size == 0 and (user.nil? or user.location.nil?)
				if args.size > 1
					return get_forecast(args[0], event, true)
				elsif args.size == 1
					return get_forecast(args[0], event)
				else
					return get_forecast(user.location, event)
				end
			end
		end
		if users.nil? or users.size == 0
			if args.size > 1
				return get_forecast(args[0], event, true)
			elsif args.size == 1
				return get_forecast(args[0], event)
			end
		end

		return "City code or zip code is required or city information must be saved."
	end
	def self.weather_save(args, event)
		user = UserModule.create_user(event)
		unless user == false
			user.location = args
			if user.save
				return "Saved location"
			else
				return "Error updating"
			end
		else
			return "An error has occurred creating user"
		end
	end
end

