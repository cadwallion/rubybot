class RubyBot
  def self,setup_config
    # load all bots commands, help, and correlation to its Object reference
    Dir['**/modules/*/config/*.yml'].each do |config|
      self.commands.merge! YAML::load(File.open(config))
    end

    # load all config vars into @config class var
    Dir['config/*.yml'].each do |config|
      self.config.merge! YAML::load(File.open(config))
    end
    
    self.connections = IRC::Utils.setup_connections(self, self.config)
  end

  def self.setup_models
    Dir['**/modules/*/models/*.rb'].each do |model|
      load model
    end
  end

  def self.setup_modules
    Dir['**/modules/*/core/*.rb'].each do |mod|
      load mod
    end
    Dir['**/modules/*'].each do |module_name|
      if module_name =~ /modules\/(.*)/
        constantize(camelize($1)+"Module").init(self) if constantize(camelize($1)+"Module").respond_to?('init')
      end
    end
  end
end
