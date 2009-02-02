require 'time'
require 'logger'

def logtime
	Time.now.strftime("%Y-%m-%d %H:%M")
end

def logger
	if @logger.nil?
		@logger = Logger.new("logs/bot.log")
		if ENV['DEBUG'] == 'true'
			@logger.level = Logger::DEBUG
		else
			@logger.level = Logger::WARN
		end
	end
	@logger
end

def log_error(err)
	logger.debug "#{err.message} at #{err.backtrace.inspect}"
end