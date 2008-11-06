require 'rubygems'
require 'lib/Ruby-IRC/IRC.rb'
require 'memcache'
require 'open-uri'
require 'rexml/document'
require 'pp'
require 'active_record'
require 'cgi'
require 'tzinfo'
require 'remote_request'
require 'hpricot'
require 'json'

load 'config.rb'
load 'database.rb'
load 'includes.rb'
load 'wowhead.rb'
load 'tvshows.rb'
load 'armory.rb'
load 'youtube.rb'
load 'weather.rb'
load 'handlers.rb'
load 'users.rb'
load 'rupture.rb'
load 'election.rb'
load 'shoutcast.rb'

def logger
  if @logger.nil?
    @logger = Logger.new("bot.log")
    @logger.level = Logger::DEBUG
  end
  @logger
end


@@loopmsg = ""

pid = fork do
  begin
    logger.info("Starting bot")
    Signal.trap('HUP', 'IGNORE') # Don't die upon logout

    pidfile = File.new("bot.pid", "w")
    pidfile.write($$)
    pidfile.close

    if @bindip.nil?
      @@bot = IRC.new(@nickname, @server_address, @server_port, @realname)
    else
      @@bot = IRC.new(@nickname, @server_address, @server_port, @realname, @bindip)
    end

    IRCEvent.add_callback('endofmotd') do |event|
      @@bot.send_message("Nickserv", "identify #{@nickserv_pass}")
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
    logger.debug(err.message)
  end
end

Process.detach(pid)
