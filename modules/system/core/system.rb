class SystemModule
  def self.reload_bot(args, event)
    event.connection.setup.reset_startup_handlers
    event.connection.setup.default_handlers
    load 'core/handlers.rb'
    setup_models
    setup_config
    setup_modules
    return "Reloaded!"
  end

  def self.kill_bot(args, event)
    event.connection.quit("QUIT :*Gets a gun* ... BAM!")
    return ""
  end

  def self.rickroll_count(args, event)
    url = "http://www.progenywow.com/zulamancount2.php"
    file = Net::HTTP.get_response URI.parse(url)
    count = file.body.gsub("\n", "")
    return "Progeny has rickrolled #{count} people."
  end

  def self.whoami(args, event)
    return "I am #{@@bot.nick}"
  end

  def self.time(args, event)
    return "It is #{Time.now.to_i}.  #{1234567890 - Time.now.to_i} seconds left."
  end

  def self.do_roll(args, event)
    if args =~ /^([0-9]*)$/i
      limit = $1.to_i
      limit = 100 if limit <= 0
      limit = limit + 3
      random_number = rand(limit)
      random_number = "00" if random_number == 0
      random_number = random_number - 2 unless random_number == "00"
      limit = limit - 3
      return "#{event.from.capitalize} rolled #{random_number.to_s} (-1-#{limit})."
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
    if command[values[0]].size > 0
      output = []
      command[values[0]].each do |comm, value|
        if comm != "command" and comm != "help" and comm != "out" and comm != "num_args" and comm != "regex"
          output = output << comm
        end
      end
      return "List of sub-commands: "+ output.join(", ") if output.size > 0
    end
    return "No help found"
  end
end
