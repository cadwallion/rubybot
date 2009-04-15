class Wow
  def self.realmstatus(args, event)
    if args =~ /^(us|eu|US|EU)$/
      if $1 == "us" or $1 == "US"
        return getrealmstatus_us
      else
        return getrealmstatus_eu
      end
    end
    if args =~ /^(us|eu|US|EU) (.*)$/
      if $1 == "us" or $1 == "US"
        return getonerealmstatus_us($2)
      else
        return getonerealmstatus_eu($2)
      end
    end
    return false
  end

  def self.notices(args, event)
    return getnotices
  end

  def self.getnotices
    output = ""
    number = 0
    url = URI.parse('http://launcher.worldofwarcraft.com/alert').to_s  
    doc = RemoteRequest.new("get").read(url)
    doc.split("\n").each do |line|
      unless line == "SERVERALERT:" or line == ""
        if line =~ /^\[.*\]$/
          number = number + 1
          line = line + " - "
        end
        return output if number > 1
        output = output + line
      end
    end
    return output
  end

  def self.getrealmstatus_us
    url = URI.parse('http://www.worldofwarcraft.com/realmstatus/index.xml').to_s  
    xmldoc = RemoteRequest.new("get").read(url)
    armoryinfo = (REXML::Document.new xmldoc).root
    if armoryinfo.elements['/rss/channel']
      i = 0
      up = 0
      down = 0
      armoryinfo.elements.each('/rss/channel/item') do |item|
        i=i+1
        status = item.elements['source'].text
        if status =~ /^(.*) Realm Up$/
          up=up+1
        else
          down=down+1
        end
      end
      return "US Realm Status: #{up}/#{i}"
    end
    return false
  end

  def self.getonerealmstatus_us(realm)
    realm = realm.gsub(/\'([a-z])/) {|s| s.upcase }
    url = URI.parse("http://www.worldofwarcraft.com/realmstatus/status-events-rss.html?r=#{URI.encode(realm)}").to_s  
    xmldoc = RemoteRequest.new("get").read(url)
    armoryinfo = (REXML::Document.new xmldoc).root
    if armoryinfo.elements['/rss/channel/item']
      status = armoryinfo.elements['/rss/channel/item/title'].text
      description = armoryinfo.elements['/rss/channel/item/description'].text
      if status =~ /^(.*) Realm Up$/
        return "Realm status for #{$1} - Status: Up - #{description}"
      elsif status =~ /^(.*) Realm Down$/
        return "Realm status for #{$1} - Status: Down"
      else
        return "Unknown status"
      end
    else
      return "Could not find realm #{realm}, check capitalization and spelling."
    end
    return false
  end

  def self.getonerealmstatus_eu(realm)
    url = URI.parse("http://www.wow-europe.com/realmstatus/index.xml").to_s  
    xmldoc = RemoteRequest.new("get").read(url)
    armoryinfo = (REXML::Document.new xmldoc).root
    if armoryinfo.elements['/rss/channel']
      armoryinfo.elements.each('/rss/channel/item') do |item|
        if item.elements['title'].text.downcase == realm.downcase
          status = item.elements['description'].text
          if status =~ /^(.*) - Realm Up - (.*) - Type (.*)$/
            return "Realm status for #{$1} (#{$3}) - Status: Up"
          elsif status =~ /^(.*) - Realm Down - (.*) - Type (.*)$/
            return "Realm status for #{$1} (#{$3}) - Status: Down"
          else
            return "Unknown status"
          end
        end
      end
      return "Could not find realm #{realm}, check capitalization and spelling."
    else
      return "Could not find realm #{realm}, check capitalization and spelling."
    end
    return false
  end

  def self.getrealmstatus_eu
    url = URI.parse('http://www.wow-europe.com/realmstatus/index.xml').to_s  
    xmldoc = RemoteRequest.new("get").read(url)
    armoryinfo = (REXML::Document.new xmldoc).root
    if armoryinfo.elements['/rss/channel']
      i = 0
      up = 0
      down = 0
      armoryinfo.elements.each('/rss/channel/item') do |item|
        i=i+1
        status = item.elements['description'].text
        if status =~ /^(.*) - Realm Up - (.*)$/
          up=up+1
        else
          down=down+1
        end
      end
      return "EU Realm Status: #{up}/#{i}"
    end
    return false
  end
end

