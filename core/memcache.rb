def setup_memcache
	begin
		@@connections.each do |name, connection|
			connection.memcache = MemCache.new "#{connection.config["memcache_host"]}:#{connection.config["memcache_port"]}", :namespace => connection.config["memcache_namespace"]
		end
	rescue => err
		log_error(err)
	end
end