class ChannelModule
  def self.join_channel(args, event)
    args = args.split
    unless Channel.find_by_name(args[0])
      channel = Channel.create(:name => args[0])
      channel.save
      reload_channels
      @@bot.add_channel(args[0])
      return "Joined #{args[0]}"
    else
      @@bot.add_channel(args[0])
      return "I am already in that channel"
    end
  end
  
  def self.part_channel(args, event)
    if event.channel =~ /^\#(.*)$/
      if channel = Channel.find_by_name(event.channel)
        channel.destroy
        channel.save
        reload_channels
        @@bot.del_channel(event.channel)
        return "Left #{event.channel}"
      else
        @@bot.del_channel(event.channel)
        return "I am not in that channel"
      end
    else
      return "You need to do that from inside a channel."
    end
  end

  def self.quiet(args, event)
    if event.channel =~ /^\#(.*)$/
      if channel = Channel.find_by_name(event.channel)
        if channel.quiet == 1
          channel.quiet = 0
          channel.save
          reload_channels
          return "Made #{event.channel} not quiet"
        else
          channel.quiet = 1
          channel.save
          reload_channels
          return "Made #{event.channel} quiet"
        end
      else
        return "Could not find channel"
      end
    else
      return "You need to do that from inside a channel."
    end
  end

  def self.is_quiet?(channel)
    if channel =~ /^\#(.*)$/
      if channel = @@channels['#'+$1]
        if channel.quiet == 1
          return true
        else
          return false
        end
      else
        return false
      end
    else
      return false
    end
  end

  def self.give_ops(args, event)
    if event.channel =~ /^\#(.*)$/
      @@bot.op(event.channel, event.from)
      return ""
    else
      return "You need to do that from inside a channel."
    end
  end
  def self.take_ops(args, event)
    if event.channel =~ /^\#(.*)$/
      @@bot.deop(event.channel, event.from)
      return ""
    else
      return "You need to do that from inside a channel."
    end
  end
  def self.kick(args, event)
    args = args.split(' ', 2)
    if event.channel =~ /^\#(.*)$/
      @@bot.kick(event.channel, args[0], args[1])
      return ""
    else
      return "You need to do that from inside a channel."
    end
  end
  def self.ban(args, event)
    args = args.split(' ', 2)
    if hostmask = UserModule.get_hostmask_for_nick(args[0])
      if event.channel =~ /^\#(.*)$/
        @@bot.mode(event.channel, hostmask, "+b")
        @@bot.kick(event.channel, args[0], args[1])
        return ""
      else
        return "You need to do that from inside a channel."
      end
    else
      return "Could not find user, try again in a few moments"
    end
  end
  def self.unban(args, event)
    args = args.split(' ', 2)
    if hostmask = UserModule.get_hostmask_for_nick(args[0])
      if event.channel =~ /^\#(.*)$/
        @@bot.mode(event.channel, hostmask, "-b")
        return ""
      else
        return "You need to do that from inside a channel."
      end
    else
      return "Could not find user, try again in a few moments"
    end
  end
  def self.reload_channels
    channels = Channel.all
    @@channels = nil
    @@channels = {}
    channels.each do |channel|
      @@channels.merge!({channel.name => channel})
    end
  end
end
