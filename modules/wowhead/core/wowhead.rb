class WowheadModule
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
      log_error(err)
      ["Error retrieving search results"]
    end
  end

  def self.display_results(args, event)
    domain = 'www.wowhead.com'
    items = search(domain, args).collect_every(5)
    itemssmall = items[0]
    itemoutput = itemssmall.join(", ")
    return "Top 5: " + itemoutput
  end
end
