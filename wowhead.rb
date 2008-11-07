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
      ["Error retrieving search results: #{err.message} at #{err.backtrace.first}"]
    end
  end

  def self.display_results(args, event)
    value = args.split(' ', 2)
    if value[0] =~ /^wotlk$/i
      domain = 'wotlk.wowhead.com'
    else
      domain = 'www.wowhead.com'
    end
    items = Wowhead.search(domain, value[1]).collect_every(5)
    itemssmall = items[0]
    itemoutput = itemssmall.join(", ")
    return "Top 5: " + itemoutput
  end
end
