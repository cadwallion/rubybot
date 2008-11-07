class ChannelModule
  def self.join_channel(args, event)
    args = args.split
    if user = User.find(:first, :include => :hosts, :conditions => ["users.admin = ? and hosts.hostname = ?", 1, event.hostmask])
      unless channel = Channel.find_by_name(args[0])
        Channel.create(:name => args[0])
        @@channels = Channel.find(:all)
        @@bot.add_channel(args[0])
        return "Joined #{args[0]}"
      else
        @@bot.add_channel(args[0])
        return "I am already in that channel"
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
          @@bot.del_channel(event.channel)
          return "I am not in that channel"
        end
      end
    else
      return "You need to do that from inside a channel."
    end
    return "You can't do that"
  end
end
