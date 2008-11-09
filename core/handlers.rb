# initialization of event handler
@message_proc = Proc.new do |event|
  begin
    IRCHandler.message(event)
  rescue => err
    log_error(err)
  end
end

@who_reply_proc = Proc.new do |event|
  begin
    IRCHandler.who_reply(event)
  rescue => err
    log_error(err)
  end
end

@join_proc = Proc.new do |event|
  begin
    IRCHandler.join(event)
  rescue => err
    log_error(err)
  end
end

@part_proc = Proc.new do |event|
  begin
    IRCHandler.part(event)
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
  
  def self.who_reply(event)
    UserModule.save_nick(event.stats[7], "#{event.stats[4]}@#{event.stats[5]}")
  end

  def self.join(event)
    if event.from == @@c['nickname']
      @@bot.get_channel_list(event.channel)
    end
    UserModule.save_nick(event.from, event.hostmask)
  end

  def self.part(event)
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
      if command['admin'] == 1
        return ["You need to be an admin.", "notice"] unless UserModule.is_admin?(event)
      end
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
end
