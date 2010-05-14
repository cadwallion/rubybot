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
require 'hpricot'
require 'net/http'
require 'uri'
require 'time'
require 'em-ruby-irc'


#require windows specific gems
if defined?(CONFIG) and CONFIG['host_os'] == "mswin32"
  require 'win32/process'
end
