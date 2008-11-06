require 'yaml'
# load all bots commands, help, and correlation to its Object reference
@@commands = YAML::load( File.open( 'commands.yml' ) )

# initialization of event handler
@message_proc = Proc.new do |event|
  IRCHandler.message(event)
end

class IRCHandler
  def self.logger
    if @logger.nil?
      @logger = Logger.new("bot.log")
      @logger.level = Logger::DEBUG
    end
    @logger
  end

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
    if event.message =~ Regexp.new("^#{COMMAND_CHAR}(.*)", true)
      # valid bot command, send to processor
      self.process_message(event)
    end

    #Youtube
    if YOUTUBELINKS == true
      # is event a youtube link?
      if event.message =~ /^http\:\/\/www\.?youtube\.com\/watch\?v\=([0-9a-zA-Z\-_]*)(\&.*)?/i
        value = $1
        unless value.nil?
          # grab youtube information
          youtube = Youtube.get_movie(value)
          @@bot.send_message(self.get_target(event), youtube) if youtube != ""
        end
      end
    end
  end

  # routes the event to the correct Object defined in commands.yml
  def self.process_message(event)
    omgthiserrors
    unless event.message.nil?
      # set to global var for use in the Object associated with the command
      @@event = event
      # check for valid bot command event.  Possibly a duplicate?
      if event.message =~ Regexp.new("^#{COMMAND_CHAR}(.*)", true)
        # slice up the information into two parts
        command_array = self.process_commands($1, @@commands)
        # crunch data down to one message Array
        message = self.do_command(command_array[0], command_array[1], event) unless command_array.nil? or command_array[0].nil? or command_array[1].nil?
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
    begin
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
    rescue => err
      logger.debug "Error: #{err.message} at #{err.backtrace.first}"
    end  
  end

  def self.do_command(command, args, event)
    begin
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
    rescue => err
      logger.debug "Error: #{err.message} at #{err.backtrace.first}"
    end  
  end

  def self.reload_bot(args, event)
      load 'database.rb'
      load 'includes.rb'
      load 'armory.rb'
      load 'wowhead.rb'
      load 'tvshows.rb'
      load 'youtube.rb'
      load 'handlers.rb'
      load 'users.rb'
      load 'weather.rb'
      load 'config.rb'
      load 'rupture.rb'
      load 'election.rb'
      load 'shoutcast.rb'
    return "Reloaded!"
  end

  def self.kill_bot(args, event)
    ADMINHOSTS.each do |adminhost|
      if event.hostmask == adminhost
        @@bot.send_quit
        return ""
      end
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


