@message_proc = Proc.new do |event|
  IRCHandler.message(event)
end

class IRCHandler
  def self.get_target(event)
    if event.channel =~ /#(.*)/
      event.channel
    else
      event.from
    end
  end
  
  def self.message(event)
    target = get_target(event)
    from_nick = event.from
    from_hostmask = event.hostmask
    if event.message =~ Regexp.new("^#{COMMAND_CHAR}(.*)", true)
      self.process_message(event)
    end
  end

  def self.process_message(event)
    #Armory links
    if event.message =~ /^.count$/i
      url = "http://www.progenywow.com/zulamancount2.php"
      file = Net::HTTP.get_response URI.parse(url)
      count = file.body.gsub("\n", "")
      @@bot.send_message(self.get_target(event), "Progeny has rickrolled #{count} people.")
    end
    #Armory links
    if event.message =~ /^.armory$/i
      @@bot.send_notice(event.from, "The format for @armory is '@armory <us/eu> <realm name> <character name>'.")
    end
    if event.message =~ /^.armory (.*)/i
      value = $1.split
      if value[0].nil? or value[1].nil? or value[2].nil?
        @@bot.send_notice(event.from, "The format for @armory is '@armory <us/eu> <realm name> <character name>'.")
      else
        if value[0] =~ /^us$/i or value[0] =~ /^eu$/i
          if value[0] =~ /^us$/i
            domain = 'www.wowarmory.com'
          else
            domain = 'eu.wowarmory.com'
          end
          @@bot.send_message(self.get_target(event), "#{value[2].capitalize}'s profile: http://#{domain}/character-sheet.xml?r=#{URI.encode(value[1].capitalize)}&n=#{URI.encode(value[2].capitalize)}")
        else
          @@bot.send_notice(event.from, "Sorry, #{value[0]} is not a valid entry.  Must be 'eu' or 'us'.")
        end
      end
    end
    #Check looping
    if event.message =~ /^.loop$/i
      @@bot.send_notice(event.from, @@loopmsg)
    end
    #Armory Char Lookup
    if event.message =~ /^.char$/i
      @@bot.send_notice(event.from, "The format for @char is '@char <us/eu> <realm name> <character name>'.")
    end
    if event.message =~ /^.char (.*)/i
      value = $1.split
      if value[0].nil? or value[1].nil? or value[2].nil?
        @@bot.send_notice(event.from, "The format for @char is '@char <us/eu> <realm name> <character name>'.")
      else
        if value[0] =~ /^us$/i or value[0] =~ /^eu$/i
          if value[0] =~ /^us$/i
            domain = 'www.wowarmory.com'
          else
            domain = 'eu.wowarmory.com'
          end
          buffs = Armory.get_buffs(domain, value[1], value[2])
          @@bot.send_message(self.get_target(event), Armory.get_stats(domain, value[1], value[2]))
          @@bot.send_message(self.get_target(event), buffs) if buffs != ""
        else
          @@bot.send_notice(event.from, "Sorry, #{value[0]} is not a valid entry.  Must be 'eu' or 'us'.")
        end
      end
    end
    #Arena Points
    if event.message =~ /^.ap$/i
      @@bot.send_notice(event.from, "The format for @ap is '@ap <5/3/2> <points>'.")
    end
    if event.message =~ /^.ap (.*)/i
      value = $1.split
      if value[0].nil? or value[1].nil?
        @@bot.send_notice(event.from, "The format for @ap is '@ap <5/3/2> <points>'.")
      else
        if value[0].to_i == 5 or value[0].to_i == 3 or value[0].to_i == 2
          @@bot.send_message(self.get_target(event), "#{value[1]} rating = " + Armory.get_points(value[0], value[1]))
        else
          @@bot.send_notice(event.from, "Sorry, #{value[0]} is not a valid entry.  Must be '2', '3' or '5'.")
        end
      end
    end
    #Armory Buff Lookup
    if event.message =~ /^.buffinfo$/i
      @@bot.send_notice(event.from, "The format for @buffinfo is '@buffinfo <us/eu> <realm name> <character name> <buff name>'.")
    end
    if event.message =~ /^.buffinfo (.*)/i
      value = $1.split
      if value[0].nil? or value[1].nil? or value[2].nil? or value[3].nil?
        @@bot.send_notice(event.from, "The format for @buffinfo is '@buffinfo <us/eu> <realm name> <character name> <buff name>'.")
      else
        if value[0] =~ /^us$/i or value[0] =~ /^eu$/i
          if value[0] =~ /^us$/i
            domain = 'www.wowarmory.com'
          else
            domain = 'eu.wowarmory.com'
          end
          buffname = ""
          (3..18).each do |buffnum|
            buffname = buffname + " " + value[buffnum] unless value[buffnum].nil?
          end
          @@bot.send_message(self.get_target(event), Armory.get_buff_info(domain, value[1], value[2], buffname))
        else
          @@bot.send_notice(event.from, "Sorry, #{value[0]} is not a valid entry.  Must be 'eu' or 'us'. #{value[3]}")
        end
      end
    end
    #TV Show Lookup
  begin
    if event.message =~ /^.tv$/i
      @@bot.send_notice(event.from, "The format for @tv is '@tv <full tv show name>'.")
    end
    if event.message =~ /^.tv (.*)/i
      showid = TVShow.search($1)
      raise "Could not find show" unless showid
      showinfo = TVShow.showinfo(showid)
      raise "Could not find showinfo" unless showinfo
      episodeinfo = TVShow.episodeinfo(showid)
      raise "Could not find episodes" unless episodeinfo
      @@bot.send_message(self.get_target(event), "#{showinfo['name']} airs on #{showinfo['airday']}s at #{showinfo['airtime'].strftime("%I:%M%p")} Pacific Time.  The next episode is on #{episodeinfo['airdate']} called '#{episodeinfo['title']}'")
    end
  rescue => err 
    @@bot.send_message(self.get_target(event), "Error: #{err}")
  end
    #Rupture Settings
    if event.message =~ /^.rupture$/i
      @@bot.send_notice(event.from, "The format for @rupture is '@rupture save <id>'.")
    end
    if event.message =~ /^.rupture (.*)/i
      value = $1.split
      if value[0].nil? or value[1].nil?
        @@bot.send_notice(event.from, "The format for @rupture is '@rupture save <id>'.")
      else
        if value[0] =~ /^save$/i
          if user = User.find_by_nickname(event.from)
            user.update_attributes('rupture' => value[1])
            user.save
          else
            user = User.create('nickname' => event.from, 'hostname' => event.hostmask, 'rupture' => value[1])
          end
          @@bot.send_message(self.get_target(event), "Saved rupture XML id as '#{value[1]}'.")
        else
          @@bot.send_notice(event.from, "Sorry, #{value[0]} is not a valid entry.  Must be 'save'.")
        end
      end
    end
    #Check spec
    if event.message =~ /^.spec$/i
      @@bot.send_notice(event.from, "The format for @spec is '@spec <tree1> <tree2> <tree3> <class>'.")
    end
    if event.message =~ /^.help$/i
      @@bot.send_message(self.get_target(event), "Type one of the following commands without any options to see available options.  Commands available: @char @armory @buffinfo @reload @weather @count @ap @roll")
    end

    #Weather Lookup
    if event.message =~ /^.weather$/i
      @@bot.send_notice(event.from, "The format for @weather is '@weather <report/forecast/search/save/reset> <city information>'  City information is not required if you have already saved it.")
    end
    if event.message =~ /^.weather (.*)/i
      value = $1.split
      user = User.find_by_nickname(event.from)
      if value[0].nil?
        @@bot.send_notice(event.from, "The format for @weather is '@weather <report/forecast/search/save/reset> <city information>' City information is not required if you have already saved it.")
      else
        if value[0] =~ /^search$/i or value[0] =~ /^report$/i or value[0] =~ /^save$/i or value[0] =~ /^reset$/i or value[0] =~ /^convert$/i or value[0] =~ /^forecast$/i
          if value[0] =~ /^search$/i
            if value[1].nil?
              @@bot.send_notice(event.from, "City name is required.")
            else
              @@bot.send_message(self.get_target(event), Weather.search(value[1]))
            end
          elsif value[0] =~ /^convert$/i
            if value[1].nil?
              @@bot.send_notice(event.from, "Value is required")
            else
              temp_c = ( value[1].to_i - 32 ) * 5 / 9
              @@bot.send_message(self.get_target(event), "#{value[1].to_s}F is #{temp_c.to_s}C")
            end
          elsif value[0] =~ /^report$/i
            if value[1].nil? and user.nil?
              @@bot.send_notice(event.from, "City code or zip code is required or city information must be saved.")
            elsif !value[1].nil?
              @@bot.send_message(self.get_target(event), Weather.get_current(value[1]))
            else
              @@bot.send_message(self.get_target(event), Weather.get_current(user.location))
            end
          elsif value[0] =~ /^save$/i
            if value[1].nil?
              @@bot.send_notice(event.from, "City code or zip code is required.")
            else
              if user = User.find_by_nickname(event.from)
                user.update_attributes('location' => value[1])
                user.save              
              else
                user = User.create('nickname' => event.from, 'hostname' => event.hostmask, 'location' => value[1])
              end
              @@bot.send_message(self.get_target(event), "Saved location")
            end
          elsif value[0] =~ /^reset$/i
            if user = User.find_by_nickname(event.from)
              if user.destroy
            @@bot.send_message(self.get_target(event), "Reset location")
              end
            end
          else
            if value[1].nil? and user.nil?
              @@bot.send_notice(event.from, "City code or zip code is required or city information must be saved.")
            elsif !value[1].nil?
              @@bot.send_message(self.get_target(event), Weather.get_forecast(value[1]))
            else
              @@bot.send_message(self.get_target(event), Weather.get_forecast(user.location))
            end
          end
        else
          @@bot.send_notice(event.from, "Sorry, #{value[0]} is not a valid entry.  Must be 'report', 'forecast', 'save', 'reset' or 'search'.")
        end
      end
    end


    #Ping
    if event.message =~ /^.ping$/i or event.message =~ /^.ping (.*)/i
      @@bot.send_message(self.get_target(event), "Pong!")
    end

    #Youtube
    if YOUTUBELINKS == true
      if event.message =~ /^http\:\/\/(www\.)?youtube\.com\/watch\?v\=([0-9a-zA-Z\-_]*)(\&.*)?/i
        value = $1
        unless value.nil?
          youtube = Youtube.get_movie(value)
          @@bot.send_message(self.get_target(event), youtube) if youtube != ""
        end
      end
    end


    #Reload
    if event.message =~ /^.reload$/i or event.message =~ /^.reload (.*)/i
      load 'database.rb'
      load 'armory.rb'
      load 'tvshows.rb'
      load 'youtube.rb'
      load 'handlers.rb'
      load 'users.rb'
      load 'weather.rb'
      load 'config.rb'
      load 'rupture.rb'
      @@bot.send_message(self.get_target(event), "Reloaded.")
    end
    #die
    if event.message =~ /^.die$/i or event.message =~ /^.die (.*)/i
      ADMINHOSTS.each do |adminhost|
        if event.hostmask == adminhost
          @@bot.send_notice(event.from, "Disconnecting.")
          @@bot.send_quit
        end
      end
      @@bot.send_notice(event.from, "You can't do that!")
    end
    #Announce
    if event.message =~ /^.me$/i
      @@bot.send_message(self.get_target(event), "I am #{@@bot.nick}")
    end
    #Rolling
    if event.message =~ /^.roll$/i
      random_number = rand(100)
      @@bot.send_message(self.get_target(event), "#{event.from.capitalize} rolled #{random_number.to_s} (0-100).")
    end
    #More Rolling
    if event.message =~ /^.roll ([0-9]*)/i
      limit = $1.to_i
      limit = 100 if limit <= 0
      random_number = rand(limit)
      @@bot.send_message(self.get_target(event), "#{event.from.capitalize} rolled #{random_number.to_s} (0-#{limit}).")
    end
  end





end


