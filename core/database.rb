DB = Sequel.connect('sqlite://db/bot.sqlite')
Sequel::Model.plugin :validation_class_methods
