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
      operation = proc do
        sleep 10
        attempt_number=0
        errors=""
        begin
          attempt_number=attempt_number+1
          if (attempt_number > 2) then
            return nil
          end
          
          uri = URI.parse(url)
          http = Net::HTTP.new(uri.host, uri.port)
          http.read_timeout = 10
          http.open_timeout = 10
          file = http.start() {|http|
            http.get(uri.path)
          }
          
#          file = Net::HTTP.get_response URI.parse(url)
          if (file.message != "OK") then
            raise InvalidResponseFromFeed, file.message
          end
        rescue Timeout::Error => err
          logger.debug "Timeout Error: #{err}, sleeping for 10 secs, and trying again (Attempt #{attempt_number})."
          errors << "Timeout Error: #{err}, sleeping for 10 secs, and trying again (Attempt #{attempt_number}).\n"
          sleep 10
          retry
        rescue Errno::ECONNREFUSED => err
          logger.debug "Connection Error: #{err}, sleeping for 10 secs, and trying again (Attempt #{attempt_number})."
          errors << "Connection Error: #{err}, sleeping for 10 secs, and trying again (Attempt #{attempt_number}).\n"
          sleep 10
          retry
        rescue SocketError => exception
          logger.debug "Socket Error: #{exception}, sleeping for 10 secs, and trying again (Attempt #{attempt_number})."
          errors << "Socket Error: #{exception}, sleeping for 10 secs, and trying again (Attempt #{attempt_number}).\n"
          sleep 10
          retry
        rescue EOFError => exception
          logger.debug "Socket Error: #{exception}, sleeping for 10 secs, and trying again (Attempt #{attempt_number})."
          errors << "Socket Error: #{exception}, sleeping for 10 secs, and trying again (Attempt #{attempt_number}).\n"
          sleep 10
          retry
        rescue InvalidResponseFromFeed => err
          logger.debug "Invalid response: #{err}, sleeping for 10 secs, and trying again (Attempt #{attempt_number})."
          errors << "Invalid response: #{err}, sleeping for 10 secs, and trying again (Attempt #{attempt_number}).\n"
          sleep 10
          retry
        rescue => err
          logger.debug "Invalid response: #{err}, sleeping for 10 secs, and trying again (Attempt #{attempt_number})."
          errors << "Invalid response: #{err}, sleeping for 10 secs, and trying again (Attempt #{attempt_number}).\n"
          sleep 10
          retry
        else
          return file.body
        end        
      end
      
      callback = proc do |res|
        return res
      end
      EM.defer(operation, callback)
    end
  end
end

class InvalidResponseFromFeed < RuntimeError
  def initialize(info)
  @info = info
  end
end
