class Weather
if !defined?(CACHE)
  CACHE = MemCache.new 'localhost:11211', :namespace => 'weather'
end
  def self.get_current(citycode)
    begin
      current_cached = CACHE.get("current_"+citycode)
      if current_cached.nil?
        output = nil
        uri = URI.parse("http://xoap.weather.com/weather/local/#{CGI.escape(citycode)}?cc=*&link=xoap&prod=xoap&par=#{WEATHER_PAR}&key=#{WEATHER_API}")
        uri
        uri.open("User-Agent" => "Mozilla/5.0 (Windows; U; Windows NT 5.1; en-US; rv:1.8.1.4) Gecko/20070515 Firefox/2.0.0.4") do |xmldoc|
          weather = (REXML::Document.new xmldoc).root
          if weather.elements['/weather/cc'] then
            current = "Location: #{weather.elements['/weather/loc/dnam'].text} - Updated at: #{weather.elements['/weather/cc/lsup'].text} - Temp: #{weather.elements['/weather/cc/tmp'].text}F - Feels like: #{weather.elements['/weather/cc/flik'].text}F Wind: #{weather.elements['/weather/cc/wind/t'].text} #{weather.elements['/weather/cc/wind/s'].text} MPH - Conditions: #{weather.elements['/weather/cc/t'].text}"
            CACHE.set("current_"+citycode, current, 30.minutes)
            current
          else
            current = "City code not found."
            CACHE.set("current_"+citycode, current, 30.minutes)
            current
          end
        end
      else
        current_cached + " (Cached)"
      end
    rescue URI::InvalidURIError
      "Could not parse URL"
    rescue => err
      "Error retrieving weather: #{err.message}"
    end
  end
  def self.get_forecast(citycode)
    begin
      forecast_cached = CACHE.get("forecast_"+citycode)
      if forecast_cached.nil?
        output = nil
        forecast = nil
        uri = URI.parse("http://xoap.weather.com/weather/local/#{CGI.escape(citycode)}?cc=*&link=xoap&dayf=5&prod=xoap&par=#{WEATHER_PAR}&key=#{WEATHER_API}")
        uri.open("User-Agent" => "Mozilla/5.0 (Windows; U; Windows NT 5.1; en-US; rv:1.8.1.4) Gecko/20070515 Firefox/2.0.0.4") do |xmldoc|
          weather = (REXML::Document.new xmldoc).root
          if weather.elements['/weather/dayf'] then
            forecast = "Location: #{weather.elements['/weather/loc/dnam'].text}"
            weather.elements.each('/weather/dayf/day') do |day|
              forecast = forecast + " | #{day.attributes["t"]} #{day.attributes["dt"]} - High: #{day.elements['hi'].text}F - Low: #{day.elements['low'].text}F"
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
        end
      else
        forecast_cached + " (Cached)"
      end
    rescue URI::InvalidURIError
      "Could not parse URL"
    rescue => err
      "Error retrieving weather: #{err.message}"
    end
  end
  def self.search(citycode)
    begin
      locations = nil
      output = nil
      uri = URI.parse("http://xoap.weather.com/search/search?where=#{CGI.escape(citycode)}")
      uri.open("User-Agent" => "Mozilla/5.0 (Windows; U; Windows NT 5.1; en-US; rv:1.8.1.4) Gecko/20070515 Firefox/2.0.0.4") do |xmldoc|
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
      end
    rescue URI::InvalidURIError
      "Could not parse URL"
    rescue => err
      "Error retrieving weather: #{err.message}"
    end
  end
end

