class L4d
  def self.player_count(args, event)
    url = "http://server.tecnobrat.com/cacti/scripts/query.php"
    file = Net::HTTP.get_response URI.parse(url)
    count = file.body.gsub("\n", "")
    return "We have #{count} players currently playing on our Left 4 Dead server."
  end
end

