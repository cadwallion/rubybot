require 'time'

def logtime
  Time.now.strftime("%Y-%m-%d %H:%M")
end

def logger
  if @logger.nil?
    @logger = Logger.new("logs/bot.log")
    @logger.level = Logger::DEBUG
  end
  @logger
end

def log_error(err)
  logger.debug "[#{logtime}] #{err.message} at #{err.backtrace.first}"
end

def log_message(message)
  logger.debug "[#{logtime}] #{message}"
end

