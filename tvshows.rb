class TVShow
  def self.search(term)
    begin
      uri = URI.parse("http://www.tvrage.com/feeds/search.php?show=#{URI.encode(term)}")
      uri.open("User-Agent" => "Mozilla/5.0 (Windows; U; Windows NT 5.1; en-US; rv:1.8.1.4) Gecko/20070515 Firefox/2.0.0.4") do |xmldoc|
        searchinfo = (REXML::Document.new xmldoc).root
        if searchinfo.elements['/Results/show[1]/name'] and searchinfo.elements['/Results/show[1]/name'].text.downcase == term.downcase
          return searchinfo.elements['/Results/show[1]/showid'].text
        else
          return false
        end
      end
    rescue => err
      return false
    end
  end
  def self.showinfo(showid)
    begin
      uri = URI.parse("http://www.tvrage.com/feeds/showinfo.php?sid=#{URI.encode(showid)}")
      uri.open("User-Agent" => "Mozilla/5.0 (Windows; U; Windows NT 5.1; en-US; rv:1.8.1.4) Gecko/20070515 Firefox/2.0.0.4") do |xmldoc|
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
      uri = URI.parse("http://www.tvrage.com/feeds/episode_list.php?sid=#{URI.encode(showid)}")
      uri.open("User-Agent" => "Mozilla/5.0 (Windows; U; Windows NT 5.1; en-US; rv:1.8.1.4) Gecko/20070515 Firefox/2.0.0.4") do |xmldoc|
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
      end
    rescue => err
      puts err
      return false
    end
  end
end
