class WeatherModule
  def self.convert_to_c(value)
    log_message value
    if value =~ /^[\-0-9]*$/
      ( value.to_i - 32 ) * 5 / 9
    else
      "N/A"
    end
  end
  def self.get_current(citycode, force=false)
    begin
      current_cached = CACHE.get("current_"+citycode)
      if current_cached.nil? or force != false
        output = nil
        url = URI.parse("http://xoap.weather.com/weather/local/#{CGI.escape(citycode)}?cc=*&link=xoap&prod=xoap&par=#{@@c['weather_par']}&key=#{@@c['weather_api']}").to_s
        xmldoc = RemoteRequest.new("get").read(url)
        weather = (REXML::Document.new xmldoc).root
        if weather.elements['/weather/cc'] then
          current = "Location: #{weather.elements['/weather/loc/dnam'].text} - Updated at: #{weather.elements['/weather/cc/lsup'].text} - Temp: #{weather.elements['/weather/cc/tmp'].text}F (#{convert_to_c(weather.elements['/weather/cc/tmp'].text)}C) - Feels like: #{weather.elements['/weather/cc/flik'].text}F (#{convert_to_c(weather.elements['/weather/cc/flik'].text)}C) - Wind: #{weather.elements['/weather/cc/wind/t'].text} #{weather.elements['/weather/cc/wind/s'].text} MPH - Conditions: #{weather.elements['/weather/cc/t'].text}"
          CACHE.set("current_"+citycode, current, 30.minutes)
          current
        else
          current = "City code not found."
          CACHE.set("current_"+citycode, current, 30.minutes)
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
  def self.get_forecast(citycode, force=false)
    begin
      forecast_cached = CACHE.get("forecast_"+citycode)
      if forecast_cached.nil? or force != false
        output = nil
        forecast = nil
        url = URI.parse("http://xoap.weather.com/weather/local/#{CGI.escape(citycode)}?cc=*&link=xoap&dayf=5&prod=xoap&par=#{@@c['weather_par']}&key=#{@@c['weather_api']}").to_s
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
            CACHE.set("forecast_"+citycode, forecast, 30.minutes) 
            forecast
          else
            forecast = "City code not found."
            CACHE.set("forecast_"+citycode, forecast, 2.hours) 
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
  def self.search(citycode)
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
    return search(args)
  end
  def self.weather_convert(args, event)
    temp_c = convert_to_c(args)
    return "#{args.to_s}F is #{temp_c.to_s}C"
  end
  def self.weather_report(args, event)
    args = args.split
    user = UserModule.get_user(event)
    if args.size == 0 and (user == false or user.nil? or user.location.nil?)
      "City code or zip code is required or city information must be saved."
    elsif args.size != 0
      if args.size > 1
        return get_current(args[0], true)
      else
        return get_current(args[0])
      end
    else
      return get_current(user.location)
    end
  end
  def self.weather_forecast(args, event)
    args = args.split
    user = UserModule.get_user(event)
    if args.size == 0 and (user == false or user.nil? or user.location.nil?)
      "City code or zip code is required or city information must be saved."
    elsif args.size != 0
      if args.size > 1
        return get_forecast(args[0], true)
      else
        return get_forecast(args[0])
      end
    else
      return get_forecast(user.location)
    end
  end
  def self.weather_save(args, event)
    user = UserModule.create_user(event)
    unless user == false
      user.update_attributes('location' => args)
      if user.save
        UserModule.generate_hostmasks
        log_message(user.inspect)
        return "Saved location"
      else
        log_message(user.inspect)
        log_message(user.hosts.inspect)
        log_message(user.errors.inspect)
        return "Error updating"
      end
    else
      return "An error has occurred creating user"
    end
  end
end

