class TvshowsModule
  def self.search(term)
    begin
      url = URI.parse("http://www.tvrage.com/feeds/search.php?show=#{URI.encode(term)}").to_s
      xmldoc = RemoteRequest.new("get").read(url)
      searchinfo = (REXML::Document.new xmldoc).root
      if searchinfo.elements['/Results/show[1]/name'] and searchinfo.elements['/Results/show[1]/name'].text.downcase == term.downcase
        return searchinfo.elements['/Results/show[1]/showid'].text
      else
        return false
      end
    rescue => err
      return false
    end
  end
  def self.showinfo(showid)
    begin
      url = URI.parse("http://www.tvrage.com/feeds/showinfo.php?sid=#{URI.encode(showid)}").to_s
      xmldoc = RemoteRequest.new("get").read(url)
        showinfo = (REXML::Document.new xmldoc).root
        if showinfo.elements['/Showinfo/showid']
          timezone = showinfo.elements['/Showinfo/timezone'].text
          if timezone =~ /GMT([\+\-][0-9]*) ([\+\-])DST/
            tz = $1.to_i - 1 if $2 == "-"
            tz = $1.to_i + 1 if $2 == "+"
          end
          tz = tz * 100
          tz = tz.to_s
          if tz =~ /^([0-9]*)$/
            tz = "+"+$1
          end
          if tz =~ /([\+\-])([0-9][0-9][0-9])$/
            tz = $1+"0"+$2
          end
          show = {
            'name' => showinfo.elements['/Showinfo/showname'].text,
            'network' => showinfo.elements['/Showinfo/network'].text,
            'airtime' => Time.parse(showinfo.elements['/Showinfo/airtime'].text+" "+tz),
            'airday' => showinfo.elements['/Showinfo/airday'].text,
          }
          return show
        else
          return false
        end
    rescue => err
      puts err
      return false
    end
  end
  def self.episodeinfo(showid)
    episodes = {}
    returnepisode = {}
    begin
      url = URI.parse("http://www.tvrage.com/feeds/episode_list.php?sid=#{URI.encode(showid)}").to_s
      xmldoc = RemoteRequest.new("get").read(url)
        episodeinfo = (REXML::Document.new xmldoc).root
        if episodeinfo.elements['/Show/Episodelist/Season/episode']
          episodeinfo.elements.each('/Show/Episodelist/Season/episode') do |episode|
            thisepisode = {
              'epnum' => episode.elements['epnum'].text,
              'seasonnum' => episode.elements['seasonnum'].text,
              'airdate' => episode.elements['airdate'].text,
              'title' => episode.elements['title'].text,
            }
            episodes.merge!({ episode.elements['airdate'].text => thisepisode })
            currentdate = Date.today
            lastdate = Date.parse("2049-01-01")
            episodes.each do |key,episode|
              episodedate = key.split("-")
              if episodedate[2] == "00" || Date.parse(key) > lastdate || Date.parse(key) < currentdate
                episodes.delete(key)
              else
                lastdate = Date.parse(key)
                returnepisode = episode
              end
            end
          end
          return returnepisode
        else
          return false
        end
    rescue => err
      puts err
      return false
    end
  end
  def self.display_info(args, event)
    showid = search(args)
    return "Could not find show" unless showid
    showinfo = showinfo(showid)
    return "Could not find showinfo" unless showinfo
    episodeinfo = episodeinfo(showid)
    return "Could not find episodes" unless episodeinfo
    return "#{showinfo['name']} airs on #{showinfo['airday']}s at #{showinfo['airtime'].strftime("%I:%M%p")} Pacific Time on network '#{showinfo['network']}.'  The next episode is on #{episodeinfo['airdate']} called '#{episodeinfo['title']}'"
  end
end
