ActiveRecord::Base.establish_connection({
      :adapter => "sqlite3", 
      :dbfile => "bot.sqlite" 
})


begin
  if !defined?(CACHE)
    CACHE = MemCache.new "#{@memcache_host}:#{@memcache_port}", :namespace => @memcache_namespace
  end
rescue => err
  log_error(err)
end

