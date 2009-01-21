#!/usr/bin/env ruby

#include Config constants for OS type
if defined?(Config)
  include Config
end

#gems
require 'rubygems'
require 'memcache'
require 'open-uri'
require 'rexml/document'
require 'pp'
require 'yaml'
require 'sequel'
require 'cgi'
require 'tzinfo'
require 'hpricot'
require 'json'
require 'net/http'
require 'uri'
require 'time'
require 'logger'

if defined?(CONFIG) and CONFIG['host_os'] == "mswin32"
  require 'win32/process'
end

#custom libraries
require 'core/logging.rb'
require 'core/lib/Ruby-IRC/IRC.rb'
require 'core/includes.rb'
require 'core/remote_request.rb'

#setup database
require 'core/database.rb'

#config
require 'core/config.rb'

#setup models from modules
setup_models

#setup config
setup_config

#setup caching
require 'core/memcache.rb'

@@channels = nil
@@channels = {}

setup_modules

#message handler, load last
load 'core/handlers.rb'

@@loopmsg = ""

#fork to the background
pid = fork do
  begin
    log_message("Starting bot")
    Signal.trap('HUP', 'IGNORE') if defined?(CONFIG) and CONFIG['host_os'] == "mswin32" # Don't die upon logout

    #open and write pid number to file
    pidfile = File.new("bot.pid", "w")
    pidfile.write($$)
    pidfile.close

    #allow bot to bind to a specific IP -- optional
    if @@c['bindip'].nil?
      @@bot = IRC.new(@@c['nickname'], @@c['server_address'], @@c['server_port'], @@c['realname'])
    else
      @@bot = IRC.new(@@c['nickname'], @@c['server_address'], @@c['server_port'], @@c['realname'], @@c['bindip'])
    end

    #after receiving the endofmotd message, start login events
    @logged_in = Proc.new do |event|
      log_message("OMG logged in!")
      # reset userlist and channels
      @@userlist = nil
      @@userlist = {}

      @@bot.send_message("Nickserv", "identify #{@@c['nickserv_pass']}") unless @@c['nickserv_pass'].nil?
      log_message("Reloading channels")
      ChannelModule.reload_channels
      
      @@channels.each do |channelname, channel|
        if channel.password.nil?
          @@bot.add_channel(channel.name)
        else
          @@bot.add_channel("#{channel.name} #{channel.password}")
        end
      end
    end

    IRCEvent.add_handler('endofmotd', @logged_in)
    IRCEvent.add_handler('nomotd', @logged_in)
    IRCEvent.add_handler('whoreply', @who_reply_proc)
    IRCEvent.add_handler('join', @join_proc)
    IRCEvent.add_handler('part', @part_proc)

    IRCEvent.add_handler('privmsg', @message_proc)
    @@bot.connect
  rescue => err
    log_error(err)
  end
end

Process.detach(pid)
