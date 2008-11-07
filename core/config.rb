configs = Config.find(:all)
@@config = []
configs.each do |config|
  @@config[config.config_name] = config.config_value
end
