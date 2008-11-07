class ElectionModule
  def self.get_results(args, event)
    return do_results
  end
  def self.get_state_results(args, event)
    return do_state_results(args)
  end
  def self.do_results
    begin
      url = URI.parse("http://election.cnn.com/results/US/national.html?").to_s
      doc = Hpricot(RemoteRequest.new("get").read(url))
      json = (doc/"//*[@id='jsCode']").inner_html
      results = JSON.parse(json.to_s)
      output = ["Country-wide Results"]
      votes = []
      results['P']['candidates'].each do |candidate|
        output = output << ["#{candidate['fname']} #{candidate['lname']}: #{candidate['cvotes']} Votes (#{candidate['vpct']}%) - #{candidate['evotes']} Electoral Votes"]
        votes = votes << candidate['votes']
      end
      output = output << ["Vote difference: #{number_with_delimiter(votes[0].to_i - votes[1].to_i, ",")}"]
      output = output << ["Precincts Reporting: #{results['P']['pctsrep']}%"]
      return output.join(' | ')
    rescue => err
      "Error retrieving search results: #{err.message}"
    end
  end
  def self.do_state_results(state)
    begin
      url = URI.parse("http://election.cnn.com/results/#{state.upcase}/races/#{state.upcase}P00.html?").to_s
      doc = Hpricot(RemoteRequest.new("get").read(url))
      json = (doc/"//*[@id='jsCode']").inner_html
      results = JSON.parse(json.to_s)
      output = ["State: #{results['state']}"]
      votes = []
      results['candidates'].each do |candidate|
        output = output << ["#{candidate['fname']} #{candidate['lname']}: #{candidate['cvotes']} Votes (#{candidate['vpct']}%) - #{candidate['evotes']} Electoral Votes"]
        votes = votes << candidate['votes']
      end
      output = output << ["Vote difference: #{number_with_delimiter(votes[0].to_i - votes[1].to_i, ",")}"]
      output = output << ["Precincts Reporting: #{results['pctsrep']}%"]
      return output.join(' | ')
    rescue => err
      "Error retrieving search results: #{err.message}"
    end
  end
  def self.number_with_delimiter(number, delimiter=",")
    number.to_s.gsub(/(\d)(?=(\d\d\d)+(?!\d))/, "\\1#{delimiter}")
  end
end
