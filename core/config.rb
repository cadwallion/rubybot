def setup_config
  # load all bots commands, help, and correlation to its Object reference
  @@commands = {}
  Dir['**/modules/*/config/*.yml'].each do |config|
    @@commands.merge! YAML::load(File.open(config))
  end

  # load all config vars into global @@c var
  configs = Conf.find(:all)
  @@c = {}
  configs.each do |config|
    @@c[config.config_name] = config.config_value
  end

  # load all channels into global @@channels
  @@channels = Channel.find(:all)
end

def setup_models
  Dir['**/modules/*/models/*.rb'].each do |model|
    load model
  end
end

def setup_modules
  Dir['**/modules/*/core/*.rb'].each do |mod|
    load mod
  end
end
