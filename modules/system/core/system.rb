class SystemModule
  def self.reload_bot(args, event)
    setup_models
    setup_config
    setup_modules
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
