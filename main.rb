require 'rubygems'
require 'lib/Ruby-IRC/IRC.rb'
require 'memcache'
require 'open-uri'
require 'rexml/document'
require 'pp'
require 'active_record'
require 'cgi'
require 'tzinfo'

load 'config.rb'
load 'database.rb'
load 'tvshows.rb'
load 'armory.rb'
load 'youtube.rb'
load 'weather.rb'
load 'handlers.rb'
load 'users.rb'
load 'rupture.rb'

@@loopmsg = ""

pid = fork do
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
        begin
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
        rescue => err
          @@bot.send_message("#progenytest", err.message)
        end
        i=i+1
        @@loopmsg = "On loop number #{i.to_s}"
        sleep(300)
      end
    end
  end

  IRCEvent.add_handler('privmsg', @message_proc)
  @@bot.connect
end

Process.detach(pid)
