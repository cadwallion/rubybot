class Wowhead
  def self.search(domain, term)
    begin
      items = []
      url = URI.parse("http://#{domain}/?search=#{URI.encode(term)}&xml").to_s
      xmldoc = RemoteRequest.new("get").read(url)
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
    rescue => err
      ["Error retrieving search results: #{err.message}"]
    end
  end
end
