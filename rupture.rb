class Rupture
  def self.get_xml(nickname, xmlstring)
    begin
      ruptureoutput = []
      uri = URI.parse("http://www.rupture.com/#{xmlstring}/feed.rss")
      uri.open("User-Agent" => "Mozilla/5.0 (Windows; U; Windows NT 5.1; en-US; rv:1.8.1.4) Gecko/20070515 Firefox/2.0.0.4") do |xmldoc|
        ruptureinfo = (REXML::Document.new xmldoc).root
        if ruptureinfo.elements['/rss/channel']
          ruptureinfo.elements.each('/rss/channel/item') do |item|
            if item.elements['link'].text =~ /^http:\/\/www\.rupture\.com\/app\/events\/detail\/(.*)$/i
              eventid = $1
              current_cached = CACHE.get("feed_url_"+eventid)
              if current_cached.nil?
                data = [{
                  'title' => item.elements['title'].text,
                  'url' => item.elements['link'].text
                }]
                ruptureoutput = ruptureoutput + data
                CACHE.set("feed_url_"+eventid, item.elements['link'].text, 1.day)
              else
                CACHE.set("feed_url_"+eventid, item.elements['link'].text, 1.day)
                return ruptureoutput
              end
            end
          end
        end
        ruptureoutput
      end
    rescue => err
      "Error retrieving rupture data: #{err.message}".to_a
    end 
  end
  def self.send_message(target, nickname, event)
    @@bot.send_message(target, "Rupture - #{nickname}: #{event["title"]} - #{event["url"]}")
  end

  def self.set_rupture(args, event)
    if user = User.find_by_nickname(event.from)
      user.update_attributes('rupture' => args)
      user.save
    else
      user = User.create('nickname' => event.from, 'hostname' => event.hostmask, 'rupture' => args)
    end
    return "Saved rupture XML id as '#{args}'."
  end
end
