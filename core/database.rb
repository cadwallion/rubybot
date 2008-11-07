ActiveRecord::Base.establish_connection({
      :adapter => "sqlite3", 
      :dbfile => "db/bot.sqlite" 
})
