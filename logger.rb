require 'time'

def logtime
  Time.now.strftime("%Y-%m-%d %H:%M")
end

def logger
  if @logger.nil?
    @logger = Logger.new("downloader.log")
    @logger.level = Logger::DEBUG
  end
  @logger
end

def log_error(message)
  logger.debug "[#{logtime}] #{message}"
end