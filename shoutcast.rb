require 'socket'
include Socket::Constants

class Shoutcast
  def self.connect(args, event)
    # this line feels deprecated...test for it later
    if args =~ /^(.*) (.*)$/
      addr = $1
      port = $2
      begin
        socket = Socket.new(AF_INET, SOCK_STREAM, 0)
        sockaddr = Socket.pack_sockaddr_in( port, addr )
        socket.connect( sockaddr )
        socket.write("GET /7 HTTP/1.1\nUser-Agent:Mozilla\n\n")
        results = socket.read
      rescue => err
        return ["Error connecting to server: #{err.message}"]
      end
      if results != nil
        # remove the extra garbage
        results = results.gsub(/^.*<body>/,'')
        results = results.gsub(/<\/body>.*/,'')
        results = results.gsub(/^.*\r\n/,'')
        # splice data into array
        data = results.split(",")
        self.output_info(data) 
      else
        return "Sorry! No Response from selected server.  Check your parameters."
      end
    end
  end
  
  # format and output of data from stream
  def self.output_info(data)
    current, status, peak, max, reported, bitrate, song = data
    if status != 0
      return "Currently playing: " + song.to_s + " | Bitrate: " + bitrate.to_s + "kbps"
    else
      return "Stream is currently offline."
    end
  end
end