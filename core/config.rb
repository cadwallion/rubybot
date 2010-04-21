class RubyBot
  def setup_db
    unless File.exist? "db/bot.sqlite"
      `sqlite3 db/bot.sqlite < sql/users.sql`
      `sqlite3 db/bot.sqlite < sql/hosts.sql`
      `sqlite3 db/bot.sqlite < sql/channels.sql`
    end
  end

  def setup_config
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

  def setup_models
    Dir['**/modules/*/models/*.rb'].each do |model|
      load model
    end
  end

  def setup_initial_data
    unless User.find(:admin => 1)
      self.config['admins'].each do |admin|
        user = User.create(:nickname => admin["nickname"].to_s, :admin => 1)
        user.add_host(Host.create(:hostmask => admin["hostmask"]))
        user.password = admin["password"]
        user.save
      end
    end
    if Channel.count == 0
      self.config['networks'].each do |name, network|
        network['channels'].each do |channel|
          Channel.create(:name => channel)
        end
      end
    end
  end

  def setup_modules
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

