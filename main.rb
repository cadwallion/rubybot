#gems
require 'rubygems'
require 'memcache'
require 'open-uri'
require 'rexml/document'
require 'pp'
require 'yaml'
require 'active_record'
require 'cgi'
require 'tzinfo'
require 'remote_request'
require 'hpricot'
require 'json'

#custom libraries
require 'logging.rb'
require 'lib/Ruby-IRC/IRC.rb'
require 'database.rb'
require 'includes.rb'

#config
load 'config.rb'

#modules
load 'wowhead.rb'
load 'tvshows.rb'
load 'armory.rb'
load 'youtube.rb'
load 'weather.rb'
load 'users.rb'
load 'rupture.rb'
load 'election.rb'
load 'shoutcast.rb'

#message handler, load last
load 'handlers.rb'

@@loopmsg = ""

#fork to the background
pid = fork do
  begin
    log_message("Starting bot")
    Signal.trap('HUP', 'IGNORE') # Don't die upon logout

    #open and write pid number to file
    pidfile = File.new("bot.pid", "w")
    pidfile.write($$)
    pidfile.close

    #allow bot to bind to a specific IP -- optional
    if @bindip.nil?
      @@bot = IRC.new(@nickname, @server_address, @server_port, @realname)
    else
      @@bot = IRC.new(@nickname, @server_address, @server_port, @realname, @bindip)
    end

    #after receiving the endofmotd message, start login events
    IRCEvent.add_callback('endofmotd') do |event|
      @@bot.send_message("Nickserv", "identify #{@nickserv_pass}") unless @nickserv_pass.nil?
      @channels.each do |channel|
        @@bot.add_channel(channel)
      end
      i = 0
      th = Thread.new do
        loop do
            users = User.find(:all, :conditions => "rupture NOT NULL")
            users.each do |user|
              events = Rupture.get_xml(user.nickname, user.rupture)
                unless events.nil?
                RUPTURE_CHANNEL.each do |rupture_channel|
                  events.each do |event|
                    Rupture.send_message(rupture_channel, user.nickname, event)
                  end
                end
              end
            end
          i=i+1
          @@loopmsg = "On loop number #{i.to_s}"
          sleep(300)
        end
      end
    end

    IRCEvent.add_handler('privmsg', @message_proc)
    @@bot.connect
  rescue => err
    log_error(err)
  end
end

Process.detach(pid)