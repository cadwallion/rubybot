def setup_config
  # load all bots commands, help, and correlation to its Object reference
  @@commands = {}
  Dir['**/modules/*/config/*.yml'].each do |config|
    @@commands.merge! YAML::load(File.open(config))
  end

  # load all config vars into global @@c var
  @@c = {}
  Dir['config/*.yml'].each do |config|
    @@c.merge! YAML::load(File.open(config))
  end
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
