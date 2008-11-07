# initialization of event handler
@message_proc = Proc.new do |event|
  begin
    IRCHandler.message(event)
  rescue => err
    log_error(err)
  end
end

class IRCHandler
  # determines if the command came from a PM or channel
  def self.get_target(event)
    if event.channel =~ /#(.*)/
      # event was a channel message
      event.channel
    else
      # event was a private message
      event.from
    end
  end
  
  # initial response block from the event handler
  def self.message(event)
    # finds the event target
    target = get_target(event)
    # finds the event originator
    from_nick = event.from
    # gets the hostmask
    from_hostmask = event.hostmask
    # validates that event is a bot command.  check based on COMMAND_CHAR regex
    if event.message =~ Regexp.new("^#{@@c['command_char']}(.*)", true)
      # valid bot command, send to processor
      self.process_message(event)
    end

    #Youtube
    if event.message =~ /^http\:\/\/www\.?youtube\.com\/watch\?v\=([0-9a-zA-Z\-_]*)(\&.*)?/i # is event a youtube link?
    youtube_id = $1
      if target =~ /^\#(.*)/ #target is a channel
        channel = Channel.find_by_name(target)
        if !channel.nil? and channel.youtube == 1
          unless youtube_id.nil?
            # grab youtube information
            youtube = Youtube.get_movie(youtube_id)
            @@bot.send_message(self.get_target(event), youtube) if youtube != ""
          end
        end
      end
    end
  end

  # routes the event to the correct Object defined in commands.yml
  def self.process_message(event)
      unless event.message.nil?
        # set to global var for use in the Object associated with the command
        @@event = event
        # check for valid bot command event.  Possibly a duplicate?
        if event.message =~ Regexp.new("^#{@@c['command_char']}(.*)", true)
          # slice up the information into two parts
          command_array = self.process_commands($1, @@commands)
          # crunch data down to one message Array
          return false if !command_array or command_array.nil? or command_array[0].nil? or command_array[1].nil?
          message = self.do_command(command_array[0], command_array[1], event) 
          if message[0].class == Array
            message[0].each do |thismessage|
              if message[1] == "notice" or $1 =~ /^help/
                @@bot.send_notice(event.from, thismessage)
              else
                @@bot.send_message(self.get_target(event), thismessage)
              end
            end
          else
            if message[1] == "notice" or $1 =~ /^help/
              @@bot.send_notice(event.from, message[0])
            else
              @@bot.send_message(self.get_target(event), message[0])
            end
          end
        end
      end
  end

  def self.process_commands(command, commands)
    this_command = command.split(' ', 2)
    unless commands[this_command[0]].nil?
      command_options = commands[this_command[0]]
      unless this_command[1].nil?
        command_next = this_command[1]
        return process_commands(command_next, command_options) if process_commands(command_next, command_options)
      end
      command_args = this_command[1].nil? ? "" : this_command[1]
      return [command_options, command_args]
    else
      return false
    end
  end

  def self.do_command(command, args, event)
    return false if command.nil?
    unless command['out'].nil?
      return [command['out'], "message"]
    end
    unless command['command'].nil?
      num_args = command['num_args'].nil? ? 0 : command['num_args'].to_i
      opts = args.split(' ')
      if opts.size < num_args or (!command['regex'].nil? and !(args =~ Regexp.new(command['regex'])))
        unless command['help'].nil?
          return [command['help'], "notice"]
        else
          return ["An unknown error has occurred", "notice"]
        end
      end
      return [eval(command['command'] + "(args, event)"), "message"]
    end
    unless command['help'].nil?
      return [command['help'], "notice"]
    end
    return ["An unknown error has occurred", "notice"]
  end

  def self.reload_bot(args, event)
    load 'modules/armory.rb'
    load 'modules/wowhead.rb'
    load 'modules/tvshows.rb'
    load 'modules/youtube.rb'
    load 'modules/weather.rb'
    load 'modules/rupture.rb'
    load 'modules/election.rb'
    load 'modules/shoutcast.rb'
    load 'core/config.rb'
    load 'core/handlers.rb'
    return "Reloaded!"
  end

  def self.kill_bot(args, event)
    if user = User.find(:first, :include => :hosts, :conditions => ["users.admin = ? and hosts.hostname = ?", 1, event.hostmask])
      @@bot.send_quit
      exit
      return ""
    end
    return "You can't do that"
  end

  def self.rickroll_count(args, event)
    url = "http://www.progenywow.com/zulamancount2.php"
    file = Net::HTTP.get_response URI.parse(url)
    count = file.body.gsub("\n", "")
    return "Progeny has rickrolled #{count} people."
  end

  def self.check_loop(args, event)
    return @@loopmsg unless @@loopmsg.nil?
    return false
  end

  def self.join_channel(args, event)
    args = args.split
    if user = User.find(:first, :include => :hosts, :conditions => ["users.admin = ? and hosts.hostname = ?", 1, event.hostmask])
      unless channel = Channel.find_by_name(args[0])
        Channel.create(:name => args[0])
        @@channels = Channel.find(:all)
        @@bot.add_channel(args[0])
        return "Joined #{args[0]}"
      end
    end
    return "You can't do that"
  end
  
  def self.part_channel(args, event)
    if event.channel =~ /^\#(.*)$/
      if user = User.find(:first, :include => :hosts, :conditions => ["users.admin = ? and hosts.hostname = ?", 1, event.hostmask])
        if channel = Channel.find_by_name(event.channel)
          channel.destroy
          @@channels = Channel.find(:all)
          @@bot.del_channel(event.channel)
          return "Left #{event.channel}"
        else
          return "Couldn't find channel"
        end
      end
    else
      return "You need to do that from inside a channel."
    end
    return "You can't do that"
  end
  
  def self.whoami(args, event)
    return "I am #{@@bot.nick}"
  end

  def self.do_roll(args, event)
    if args =~ /^([0-9]*)$/i
      limit = $1.to_i
      limit = 100 if limit <= 0
      random_number = rand(limit)
      return "#{event.from.capitalize} rolled #{random_number.to_s} (0-#{limit})."
    else
      random_number = rand(100)
      "#{event.from.capitalize} rolled #{random_number.to_s} (0-100)."
    end
  end

  def self.do_help(args, event)
    if args != ""
      return get_help(@@commands, args)
    end
    output = []
    @@commands.each do |command, value|
      output = output << command
    end
    return "List of commands: "+ output.join(", ")
  end

  def self.get_help(command, args)
    values = args.split(' ', 2)
    unless command[values[0]].nil? or values[1].nil?
      return self.get_help(command[values[0]], values[1])
    end
    unless command[values[0]]['help'].nil?
      return command[values[0]]['help']
    end
    return "No help found"
  end
end
