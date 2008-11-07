class UserModule
  def self.get_user(event)
    if user = User.find_by_nickname(event.from)
      return user
    else
      return false
    end
  end
  def self.is_admin?(event)
    if user = get_user(event)
      return true if user.admin == 1
    end
    return false
  end
  def self.add_user(args, event)
    args = args.split
    unless User.find_by_nickname(args[0])
      user = User.create(:nickname => args[0])
      user.hosts.create(:hostname => args[1])
      return "User created"
    end
  end
  def self.get_hostmask(args, event)
    return IRCUtil.assert_hostmask(event.hostmask, make_hostmask(event.hostmask))
  end
  def self.make_hostmask(hostmask)
    user = hostmask.split('@', 2)[0]
    host = hostmask.split('@', 2)[1]
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
end
