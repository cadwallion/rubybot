begin
  if !defined?(CACHE)
    CACHE = MemCache.new "#{@@c['memcache_host']}:#{@@c['memcache_port']}", :namespace => @@c['memcache_namespace']
  end
rescue => err
  log_error(err)
end

