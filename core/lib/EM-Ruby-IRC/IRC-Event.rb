require 'yaml'

# This is a lookup class for IRC event name mapping
class EventLookup
	@@lookup = YAML.load_file("#{File.dirname(__FILE__)}/eventmap.yml")
	
	# returns the event name, given a number
	def EventLookup::find_by_number(num)
		return @@lookup[num.to_i]
	end
end

# This is a lookup class for IRC event name mapping
module IRC	
	class Event
		attr_reader :hostmask, :message, :event_type, :from, :channel, :target, :mode, :stats
		attr_accessor :connection
		def initialize(data, connection)
			@connection = connection
			data.chomp!
			data.sub!(/^:/, '')
			mess_parts = data.split(':', 2);
			unless mess_parts.nil? or mess_parts.size < 2
				# mess_parts[0] is server info
				# mess_parts[1] is the message that was sent
				@message = mess_parts[1]
				@stats = mess_parts[0].scan(/[\/\=\-\_\~\"\`\|\^\{\}\[\]\w.\#\@\+]+/)
				unless @stats[0].nil?
					if @stats[0].match(/^PING/)
						@event_type = 'ping'
					elsif @stats[1] && @stats[1].match(/^\d+$/)
						@event_type = EventLookup::find_by_number(@stats[1]);
						@channel = @stats[3].downcase unless @stats[3].nil?
						@channel = @stats[3] if @stats[3].nil?
					else
						@event_type = @stats[2].downcase if @stats[2]
					end
			
					if @event_type != 'ping'
						@from    = @stats[0].downcase
					end
					
					# FIXME: this list would probably be more accurate to exclude commands than to include them
					@hostmask = @stats[1] if %W(topic privmsg join).include? @event_type
					@channel = @stats[3].downcase if @stats[3] && !@channel
					@target  = @stats[5].downcase if @stats[5]
					@mode    = @stats[4] if @stats[4]
					run_handlers(@event_type) unless @event_type.nil?
				end
			end
			#logger.debug(data)
		end
	
		def run_handlers(event_type)
			begin
				return if connection.irc_handlers.size == 0 or connection.irc_handlers[event_type].nil?
				connection.irc_handlers[event_type].each do |handler|
					handler.call(self) unless handler.nil?
				end
			rescue => err
				log_error(err)
			end
		end
	end
end
