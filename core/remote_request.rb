class RemoteRequest
  def initialize(method)
    method = 'get' if method.nil?
    @opener = self.class.const_get(method.capitalize)
  end

  def read(url)
    a = Time.now
    log_message "Getting #{url}"
    data = @opener.read(url)
    b = Time.now
    log_message "Took #{b-a}s to get #{url}"
    data
  end

private
  class Get
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
        log_message "Timeout Error: #{err}, sleeping for 10 secs, and trying again (Attempt #{attempt_number})."
        errors << "Timeout Error: #{err}, sleeping for 10 secs, and trying again (Attempt #{attempt_number}).\n"
        sleep 10
        retry
      rescue Errno::ECONNREFUSED => err
        log_message "Connection Error: #{err}, sleeping for 10 secs, and trying again (Attempt #{attempt_number})."
        errors << "Connection Error: #{err}, sleeping for 10 secs, and trying again (Attempt #{attempt_number}).\n"
        sleep 10
        retry
      rescue SocketError => exception
        log_message "Socket Error: #{exception}, sleeping for 10 secs, and trying again (Attempt #{attempt_number})."
        errors << "Socket Error: #{exception}, sleeping for 10 secs, and trying again (Attempt #{attempt_number}).\n"
        sleep 10
        retry
      rescue EOFError => exception
        log_message "Socket Error: #{exception}, sleeping for 10 secs, and trying again (Attempt #{attempt_number})."
        errors << "Socket Error: #{exception}, sleeping for 10 secs, and trying again (Attempt #{attempt_number}).\n"
        sleep 10
        retry
      rescue InvalidResponseFromFeed => err
        log_message "Invalid response: #{err}, sleeping for 10 secs, and trying again (Attempt #{attempt_number})."
        errors << "Invalid response: #{err}, sleeping for 10 secs, and trying again (Attempt #{attempt_number}).\n"
        sleep 10
        retry
      rescue => err
        log_message "Invalid response: #{err}, sleeping for 10 secs, and trying again (Attempt #{attempt_number})."
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
