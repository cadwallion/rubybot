class Wowhead
  def self.search(domain, term)
    begin
      items = []
      uri = URI.parse("http://#{domain}/?search=#{URI.encode(term)}&xml")
      uri.open("User-Agent" => "Mozilla/5.0 (Windows; U; Windows NT 5.1; en-US; rv:1.8.1.4) Gecko/20070515 Firefox/2.0.0.4") do |xmldoc|
        searchinfo = (REXML::Document.new xmldoc).root
        if searchinfo.elements['/wowhead/items'] and searchinfo.elements['/wowhead/items'].attributes.any? then
          searchinfo.elements.each('/wowhead/items/item') do |item|
            items << ["#{item.elements['name'].text}: http://#{domain}/?item=#{item.attributes['id']}"]
            # items << ["#{item.inspect}"]
          end
          items
        else
          ["No results found."]
        end
      end
    rescue => err
      ["Error retrieving search results: #{err.message}"]
    end
  end
end
