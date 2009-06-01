#!/usr/bin/env ruby

#require active record
require 'rubygems'
require 'sequel'

#setup database
require 'core/database.rb'

load 'core/config.rb'

#models
setup_models
setup_config

#Bot user details
Conf.create(:config_name => 'nickname', :config_value => 'TecnoBotter')
Conf.create(:config_name => 'realname', :config_value => 'See TecnoBrat')
Conf.create(:config_name => 'username', :config_value => 'tecnobrat')
Conf.create(:config_name => 'nickserv_pass', :config_value => 'sylv3ster') #optional

#Connection details
Conf.create(:config_name => 'server_address', :config_value => 'irc.freenode.net')
Conf.create(:config_name => 'server_port', :config_value => '6667')
# Conf.create(:config_name => 'bindip', :config_value => '') #optional

#Bot settings
Conf.create(:config_name => 'command_char', :config_value => '@')

#Memcache settings
Conf.create(:config_name => 'memcache_host', :config_value => 'localhost')
Conf.create(:config_name => 'memcache_port', :config_value => '11211')
Conf.create(:config_name => 'memcache_namespace', :config_value => 'rubybot')

#Weather module settings
Conf.create(:config_name => 'weather_par', :config_value => '')
Conf.create(:config_name => 'weather_api', :config_value => '')

#Pownce module settings
Conf.create(:config_name => 'pownce_api_key', :config_value => '')
Conf.create(:config_name => 'pownce_api_secret', :config_value => '')

#Add user
user = User.create(:nickname => 'TecnoBrat', :admin => 1)
host = Host.create(:hostmask => 'i=tecnobra@tecnobrat.com')
user.add_host(host)

#Add channels
Channel.create(:name => '#rubybot')