#!/usr/bin/env ruby

#include Config constants for OS type
include Config

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
require 'hpricot'
require 'json'
require 'net/http'
require 'uri'
require 'time'

if CONFIG['host_os'] == "mswin32"
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

setup_modules

#message handler, load last
load 'core/handlers.rb'

@@loopmsg = ""

#fork to the background
pid = fork do
  begin
    log_message("Starting bot")
    Signal.trap('HUP', 'IGNORE') if CONFIG['host_os'] != "mswin32" # Don't die upon logout

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
    IRCEvent.add_callback('endofmotd') do |event|
      @@bot.send_message("Nickserv", "identify #{@@c['nickserv_pass']}") unless @@c['nickserv_pass'].nil?
      @@channels.each do |channel|
        if channel.password.nil?
          @@bot.add_channel(channel.name)
        else
          @@bot.add_channel("#{channel.name} #{channel.password}")
        end
      end
      i = 0
      th = Thread.new do
        loop do
          users = User.find(:all, :conditions => "rupture NOT NULL")
          users.each do |user|
            events = Rupture.get_xml(user.nickname, user.rupture)
            unless events.nil?
              @@channels.each do |channel|
                if channel.rupture == 1
                  events.each do |event|
                    Rupture.send_message(rupture_channel, user.nickname, event)
                  end
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
