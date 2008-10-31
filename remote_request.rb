require 'net/http'
require 'uri'

class RemoteRequest

  def logtime
    TimeKeeper.now.strftime("%Y-%m-%d %H:%M")
  end

  def logger
    if @logger.nil?
      @logger = Logger.new("downloader.log")
      @logger.level = Logger::DEBUG
    end
    @logger
  end

  def initialize(method)
    method = 'get' if method.nil?
    @opener = self.class.const_get(method.capitalize)
  end

  def read(url)
    a = TimeKeeper.now
    data = @opener.read(url)
    b = TimeKeeper.now
    logger.debug "[#{logtime}] Took #{b-a}s to get #{url}"
    data
  end

private
  class Get
    def self.logtime
      Time.now.strftime("%Y-%m-%d %H:%M")
    end
    def self.logger
      if @logger.nil?
        @logger = Logger.new("downloader.log")
        @logger.level = Logger::DEBUG
      end
      @logger
    end
  
    def self.read(url)
      attempt_number=0
      errors=""
      begin
        attempt_number=attempt_number+1
        if (attempt_number > 10) then
          return nil
        end
        
        file = Net::HTTP.get_response URI.parse(url)
        if (file.message != "OK") then
          raise InvalidResponseFromFeed, file.message
        end
      rescue Timeout::Error => err
        self.logger.debug "[#{logtime}] Timeout Error: #{err}, sleeping for 10 secs, and trying again (Attempt #{attempt_number})."
        errors << "Timeout Error: #{err}, sleeping for 10 secs, and trying again (Attempt #{attempt_number}).\n"
        sleep 10
        retry
      rescue Errno::ECONNREFUSED => err
        self.logger.debug "[#{logtime}] Connection Error: #{err}, sleeping for 10 secs, and trying again (Attempt #{attempt_number})."
        errors << "Connection Error: #{err}, sleeping for 10 secs, and trying again (Attempt #{attempt_number}).\n"
        sleep 10
        retry
      rescue SocketError => exception
        self.logger.debug "[#{logtime}] Socket Error: #{exception}, sleeping for 10 secs, and trying again (Attempt #{attempt_number})."
        errors << "Socket Error: #{exception}, sleeping for 10 secs, and trying again (Attempt #{attempt_number}).\n"
        sleep 10
        retry
      rescue EOFError => exception
        self.logger.debug "[#{logtime}] Socket Error: #{exception}, sleeping for 10 secs, and trying again (Attempt #{attempt_number})."
        errors << "Socket Error: #{exception}, sleeping for 10 secs, and trying again (Attempt #{attempt_number}).\n"
        sleep 10
        retry
      rescue InvalidResponseFromFeed => err
        self.logger.debug "[#{logtime}] Invalid response: #{err}, sleeping for 10 secs, and trying again (Attempt #{attempt_number})."
        errors << "Invalid response: #{err}, sleeping for 10 secs, and trying again (Attempt #{attempt_number}).\n"
        sleep 10
        retry
      rescue => err
        self.logger.debug "[#{logtime}] Invalid response: #{err}, sleeping for 10 secs, and trying again (Attempt #{attempt_number})."
        errors << "Invalid response: #{err}, sleeping for 10 secs, and trying again (Attempt #{attempt_number}).\n"
        sleep 10
        retry
      else
        return file.body
      end
    end
  end
end

class InvalidResponseFromFeed < RuntimeError
  def initialize(info)
  @info = info
  end
end
