class Youtube
  def self.get_movie(movie)
    begin
      uri = URI.parse("http://gdata.youtube.com/feeds/videos/#{URI.encode(movie)}")
      uri.open("User-Agent" => "Mozilla/5.0 (Windows; U; Windows NT 5.1; en-US; rv:1.8.1.4) Gecko/20070515 Firefox/2.0.0.4") do |xmldoc|
        youtubeinfo = (REXML::Document.new xmldoc).root
        if youtubeinfo.elements['/entry'] and youtubeinfo.elements['/entry/title'] then
          youtube = {
            'title' => youtubeinfo.elements['/entry/title'].text,
            'duration' => youtubeinfo.elements['/entry/media:group/yt:duration'].attributes['seconds'],
            'views' => youtubeinfo.elements['/entry/yt:statistics'].attributes['viewCount'],
            'rating' => youtubeinfo.elements['/entry/gd:rating'].attributes['average'],
            'ratings' => youtubeinfo.elements['/entry/gd:rating'].attributes['numRaters'],
            'comments' => youtubeinfo.elements['/entry/gd:comments/gd:feedLink'].attributes['countHint'],
          }
          "Youtube Video Info - Title: #{youtube['title']} - Duration: #{youtube['duration']} seconds - Views: #{youtube['views']} - Rating: #{youtube['rating']} (#{youtube['ratings']} ratings) - Comments: #{youtube['comments']}"
        else
          ""
        end
      end
    rescue => err
      "Error retrieving youtube info: #{err.message}"
    end
  end
end
