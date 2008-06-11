require 'rubygems'
require 'lib/Ruby-IRC/IRC.rb'
require 'memcache'
require 'open-uri'
require 'rexml/document'
require 'pp'
require 'active_record'
require 'cgi'
load 'config.rb'
load 'database.rb'
load 'armory.rb'
load 'youtube.rb'
load 'weather.rb'
load 'handlers.rb'
load 'users.rb'

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
  end

  IRCEvent.add_handler('privmsg', @message_proc)
  @@bot.connect
end

Process.detach(pid)
