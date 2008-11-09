class UserModule
  ## IRC COMMAND HANDLERS ##
  def self.add_user(args, event)
    args = args.split
    nickname = args[0].downcase
    unless User.find_by_nickname(nickname)
      hostmask = get_hostmask_for_nick(nickname)
      user = User.create(:nickname => nickname)
      user.hosts.create(:hostmask => hostmask)
      generate_hostmasks
      return "#{nickname} created with hostmask #{hostmask}"
    end
    return "That user already exists"
  end
  def self.reload_hostmasks(args, event)
    UserModule.generate_hostmasks
    return "Reloaded users."
  end

  ## UTILITY COMMANDS ##
  def self.get_hostmasks(event)
    hostmasks = @@hostmasks.select {|k,v| compare_hostmask(event.hostmask, k)}
    return hostmasks
  end
  def self.is_admin?(event)
    if hostmasks = get_hostmasks(event)
      hostmasks.each do |hostmask|
        if hostmask[1][1] == 1
          return true
        end
      end
    end
    return false
  end

  def self.compare_hostmask(usermask, wildcardmask)
    return IRCUtil.assert_hostmask(usermask, wildcardmask)
  end
  def self.get_hostmask(args, event)
    nick = args.split[0].downcase
    hostname = get_nick(nick)[:hostname]
    return make_hostmask(hostname) unless hostname == false or hostname.nil? or hostname == ""
    return "Error generating hostmast for user #{nick}"
  end
  def self.make_hostmask(hostname)
    log_message("Generating hostmask for #{hostname}")
    user = hostname.split('@', 2)[0]
    host = hostname.split('@', 2)[1]
    if host =~ /^(?:\d{1,3}\.){3}\d{1,3}$/
      hostsplit = host.split('.')
      host = "#{hostsplit[0]}.#{hostsplit[1]}.#{hostsplit[2]}.*"
    elsif host =~ /^.*(\..*\..*)$/
      host = "*#{$1}"
    end
    if user =~ /^(n|i)\=(.*)$/
      user = "#{$2}"
    elsif user =~ /^\~(.*)$/
      user = "#{$1}"
    end
    return "*#{user}@#{host}"
  end
  # save user to userlist global variable and 
  def self.save_nick(nick, hostname)
    nick = nick.downcase
    @@userlist = @@userlist.merge({nick => {:hostname => hostname}})
    return @@userlist[nick]
  end
  def self.get_nick(nick)
    nick = nick.downcase
    return @@userlist[nick] unless @@userlist[nick].nil?
    @@bot.get_user_info(nick)
    return false
  end
  def self.get_hostmask_for_nick(nick)
    nick = nick.split[0].downcase
    hostname = get_nick(nick)[:hostname]
    return make_hostmask(hostname) unless hostname == false or hostname.nil? or hostname == ""
    return false
  end
  def self.generate_hostmasks
    # load all users into global @@hostmasks
    users = User.find(:all, :include => [:hosts])
    users.each do |user|
      user.hosts.each do |host|
        @@hostmasks[host.hostmask] = [user.nickname, user.admin]
      end
    end
  end
end

@@hostmasks = nil
@@hostmasks = {}
UserModule.generate_hostmasks
