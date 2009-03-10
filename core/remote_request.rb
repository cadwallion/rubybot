class RemoteRequest
  def initialize(method)
    method = 'get' if method.nil?
    @opener = self.class.const_get(method.capitalize)
  end

  def read(url)
    a = Time.now
    logger.debug "Getting #{url}"
    data = @opener.read(url)
    b = Time.now
    logger.debug "Took #{b-a}s to get #{url}"
    data
  end

private
  class Get
    def self.read(url)
      EventMachine.run
        attempt_number=0
        begin
          attempt_number=attempt_number+1
          if (attempt_number > 2) then
            return nil
            EventMachine.stop
          end
          
          uri = URI.parse(url)
          
          req = EventMachine::Protocols::HttpClient.request(uri.host, uri.path)
          req.callback do |response|
            return response[:body]
            EventMachine.stop
          end
          
          req.errback do |response|
            logger.debug "Error from HTTP request: #{response[:status]}"
            sleep 10
            retry
          end
        rescue Timeout::Error => err
          logger.debug "Timeout Error: #{err}, sleeping for 10 secs, and trying again (Attempt #{attempt_number})."
          sleep 10
          retry
        rescue Errno::ECONNREFUSED => err
          logger.debug "Connection Error: #{err}, sleeping for 10 secs, and trying again (Attempt #{attempt_number})."
          sleep 10
          retry
        rescue SocketError => exception
          logger.debug "Socket Error: #{exception}, sleeping for 10 secs, and trying again (Attempt #{attempt_number})."
          sleep 10
          retry
        rescue EOFError => exception
          logger.debug "Socket Error: #{exception}, sleeping for 10 secs, and trying again (Attempt #{attempt_number})."
          sleep 10
          retry
        rescue InvalidResponseFromFeed => err
          logger.debug "Invalid response: #{err}, sleeping for 10 secs, and trying again (Attempt #{attempt_number})."
          sleep 10
          retry
        rescue => err
          logger.debug "Invalid response: #{err}, sleeping for 10 secs, and trying again (Attempt #{attempt_number})."
          sleep 10
          retry
        else
          return file.body
        end
      end
    end
  end
end

class InvalidResponseFromFeed < RuntimeError
  def initialize(info)
  @info = info
  end
end
