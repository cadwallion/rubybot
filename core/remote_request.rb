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
      begin
        EventMachine.run do
          attempt_number=0
          errors=""
          begin
            attempt_number=attempt_number+1
            if (attempt_number > 2) then
              return nil
              EventMachine.stop
            end
            
            uri = URI.parse(url)
            http = EventMachine::Protocols::HttpClient.request(:host => uri.host, :port => uri.port, :request => uri.path)
            http.callback do |r|
              logger.debug(r.inspect)
              if (r[:status] != "OK") then
                logger.debug "Invalid response: #{r[:status]}, sleeping for 10 secs, and trying again (Attempt #{attempt_number})."
              else
                return r[:content]
                EventMachine.stop
              end
            end
            http.errback do |r|
              logger.debug(r.inspect)
              logger.debug "Invalid response: #{r[:status]}, sleeping for 10 secs, and trying again (Attempt #{attempt_number})."
            end
            EventMachine.add_timer(5) do
              http.set_deferred_status :failed, "Timeout"
            end
          rescue => err
            logger.debug "Invalid response: #{err}, sleeping for 10 secs, and trying again (Attempt #{attempt_number})."
            sleep 10
            retry
          else
            sleep 10
            retry
          end    
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
