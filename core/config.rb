# load all bots commands, help, and correlation to its Object reference
@@commands = YAML::load( File.open( 'config/commands.yml' ) )

# load all config vars into global @@c var
configs = Conf.find(:all)
@@c = {}
configs.each do |config|
  @@c[config.config_name] = config.config_value
end

# load all channels into global @@channels
@@channels = Channel.find(:all)
