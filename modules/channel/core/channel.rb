class ChannelModule
  def self.join_channel(args, event)
    args = args.split
    unless Channel.find_by_name(args[0])
      Channel.create(:name => args[0])
      @@channels = Channel.find(:all)
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
        @@channels = Channel.find(:all)
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
end
