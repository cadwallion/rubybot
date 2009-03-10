# ---------------------------------------------------------------------------
# collect_every(n [,fill=false[,offset=0]])                  => an array
# collect_every(n [,fill=false[,offset=0]]) {|item| block}   => an_array
# ---------------------------------------------------------------------------
# If a block is given, it invokes the block passing in an array of n elements.
# The last array passed may not contain n elements if size % 2 does not equal
# zero. If no block is given, it returns an array containing the collections.
#
# If the optional argument fill is set to true, the empty spaces will be
# filled with nils. The optional argument offset allows the collection to 
# start at that index in the array.
#
# a = (1..10).to_a
# a.collect_every(5)               #=> [[1, 2, 3, 4, 5], [6, 7, 8, 9, 10]]
# a.collect_every(5) {|x| p x}     #=> [1, 2, 3, 4, 5]
#                                      [6, 7, 8, 9, 10]
# b = (1..7).to_a
# b.collect_every(3)               #=> [[1, 2, 3], [4, 5, 6], [7]]
# b.collect_every(3,true)          #=> [[1, 2, 3], [4, 5, 6], [7,nil,nil]]
# b.collect_every(3,true,1)        #=> [[2, 3, 4], [5, 6, 7]]

class Array
  def collect_every(n,fill=false,offset=0)

    if block_given?
      while offset < size
        ret=[]

        if fill
          n.times do |x| 
            if offset+x > size - 1: ret << nil
            else ret << self[offset+x] end
          end
        else
          n.times { |x| ret << self[offset+x] unless offset+x > size-1 }
        end

        offset += n
        yield ret
        ret = nil
      end

    else
      ret = []
      while offset < size
        ret << []

        if fill
          n.times do |x|
            if offset+x > size - 1: ret.last << nil
            else ret.last << self[offset+x] end
          end
        else
          n.times { |x| ret.last << self[offset+x] unless offset+x > size-1 }
        end

        offset += n
      end
      return ret
    end

  end
end

module Net
  class HTTP
      def request_get(path, initheader = {'User-Agent' => "Mozilla/5.0 (Windows; U; Windows NT 5.1; en-US; rv:1.8.1.4) Gecko/20070515 Firefox/2.0.0.4"}, &block) # :yield: +response+
        request(Get.new(path, initheader), &block)
      end
  end
end


module EventMachine
module Protocols

class HttpClient < Connection
  def send_request args
    args[:verb] ||= args[:method] # Support :method as an alternative to :verb.
    args[:verb] ||= :get # IS THIS A GOOD IDEA, to default to GET if nothing was specified?

    verb = args[:verb].to_s.upcase
    unless ["GET", "POST", "PUT", "DELETE", "HEAD"].include?(verb)
      set_deferred_status :failed, {:status => 0} # TODO, not signalling the error type
      return # NOTE THE EARLY RETURN, we're not sending any data.
    end

    request = args[:request] || "/"
    unless request[0,1] == "/"
      request = "/" + request
    end

    qs = args[:query_string] || ""
    if qs.length > 0 and qs[0,1] != '?'
      qs = "?" + qs
    end

    version = args[:version] || "1.1"
    user_agent = args[:user_agent] || "Ruby EventMachine"

    # Allow an override for the host header if it's not the connect-string.
    host = args[:host_header] || args[:host] || "_"
    # For now, ALWAYS tuck in the port string, although we may want to omit it if it's the default.
    port = args[:port]

    # POST items.
    postcontenttype = args[:contenttype] || "application/octet-stream"
    postcontent = args[:content] || ""
    raise "oversized content in HTTP POST" if postcontent.length > MaxPostContentLength

    # ESSENTIAL for the request's line-endings to be CRLF, not LF. Some servers misbehave otherwise.
    # TODO: We ASSUME the caller wants to send a 1.1 request. May not be a good assumption.
    req = [
      "#{verb} #{request}#{qs} HTTP/#{version}",
      "Host: #{host}:#{port}",
      "User-agent: #{user_agent}",
    ]

    if verb == "POST" || verb == "PUT"
      req << "Content-type: #{postcontenttype}"
      req << "Content-length: #{postcontent.length}"
    end

    # TODO, this cookie handler assumes it's getting a single, semicolon-delimited string.
    # Eventually we will want to deal intelligently with arrays and hashes.
    if args[:cookie]
      req << "Cookie: #{args[:cookie]}"
    end

    # Basic-auth stanza contributed by Mike Murphy.
    if args[:basic_auth]
      basic_auth_string = ["#{args[:basic_auth][:username]}:#{args[:basic_auth][:password]}"].pack('m').strip
      req << "Authorization: Basic #{basic_auth_string}"
    end 

    req << ""
    reqstring = req.map {|l| "#{l}\r\n"}.join
    send_data reqstring

    if verb == "POST" || verb == "PUT"
      send_data postcontent
    end
  end
end
end
end
