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
    return data
  end

private
  class Get
    def self.read(url)
      begin
        timeout(10) do
          file = Net::HTTP.get_response URI.parse(url)
          if (file.message != "OK") then
            raise InvalidResponseFromFeed, file.message
          end
          return file.body
        end
      rescue TimeoutError => err
        logger.debug "Timeout Error: #{err}."
        log_error(err)
      rescue Timeout::Error => err
        logger.debug "Timeout Error: #{err}."
        log_error(err)
      rescue Errno::ECONNREFUSED => err
        logger.debug "Connection Error: #{err}."
        log_error(err)
      rescue SocketError => err
        logger.debug "Socket Error: #{err}."
        log_error(err)
      rescue EOFError => err
        logger.debug "Socket Error: #{err}."
        log_error(err)
      rescue InvalidResponseFromFeed => err
        logger.debug "Invalid response: #{err}."
        log_error(err)
      rescue => err
        logger.debug "Unknown Error: #{err}."
        log_error(err)
      end
      return nil
    end
  end
end

class InvalidResponseFromFeed < RuntimeError
  def initialize(info)
  @info = info
  end
end
