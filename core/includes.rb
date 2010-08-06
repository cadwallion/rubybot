# ---------------------------------------------------------------------------
# collect_every(n [,fill=false[,offset=0]])                  => an array
# collect_every(n [,fill=false[,offset=0]]) {|item| block}   => an_array
# ---------------------------------------------------------------------------
# If a block is given, it invokes the block passing in an array of n elements.
# The last array passed may not contain n elements if size % 2 does not equal
# zero. If no block is given, it returns an array containing the collections.
#
# If the optional argument fill is set to true, the empty spaces will be
# filled with nils. The optional argument offset allows the collection to 
# start at that index in the array.
#
# a = (1..10).to_a
# a.collect_every(5)               #=> [[1, 2, 3, 4, 5], [6, 7, 8, 9, 10]]
# a.collect_every(5) {|x| p x}     #=> [1, 2, 3, 4, 5]
#                                      [6, 7, 8, 9, 10]
# b = (1..7).to_a
# b.collect_every(3)               #=> [[1, 2, 3], [4, 5, 6], [7]]
# b.collect_every(3,true)          #=> [[1, 2, 3], [4, 5, 6], [7,nil,nil]]
# b.collect_every(3,true,1)        #=> [[2, 3, 4], [5, 6, 7]]

class Array
  def collect_every(n,fill=false,offset=0)

    if block_given?
      while offset < size
        ret=[]

        if fill
          n.times do |x| 
            if offset+x > size - 1: ret << nil
            else ret << self[offset+x] end
          end
        else
          n.times { |x| ret << self[offset+x] unless offset+x > size-1 }
        end

        offset += n
        yield ret
        ret = nil
      end

    else
      ret = []
      while offset < size
        ret << []

        if fill
          n.times do |x|
            if offset+x > size - 1: ret.last << nil
            else ret.last << self[offset+x] end
          end
        else
          n.times { |x| ret.last << self[offset+x] unless offset+x > size-1 }
        end

        offset += n
      end
      return ret
    end

  end
end

module Net
  class HTTP
      def request_get(path, initheader = {'User-Agent' => "Mozilla/5.0 (Windows; U; Windows NT 5.1; en-US; rv:1.8.1.4) Gecko/20070515 Firefox/2.0.0.4"}, &block) # :yield: +response+
        request(Get.new(path, initheader), &block)
      end
  end
end

def constantize(camel_cased_word)
  unless /\A(?:::)?([A-Z]\w*(?:::[A-Z]\w*)*)\z/ =~ camel_cased_word
    raise NameError, "#{camel_cased_word.inspect} is not a valid constant name!"
  end

  Object.module_eval("::#{$1}", __FILE__, __LINE__)
end

def camelize(lower_case_and_underscored_word, first_letter_in_uppercase = true)
  if first_letter_in_uppercase
    lower_case_and_underscored_word.to_s.gsub(/\/(.?)/) { "::" + $1.upcase }.gsub(/(^|_)(.)/) { $2.upcase }
  else
    lower_case_and_underscored_word.first + camelize(lower_case_and_underscored_word)[1..-1]
  end
end

def html2text(html)
  text = html.
    gsub(/(&nbsp;|\n|\s)+/im, ' ').squeeze(' ').strip.
    gsub(/<([^\s]+)[^>]*(src|href)=\s*(.?)([^>\s]*)\3[^>]*>\4<\/\1>/i, '\4')

  links = []
  linkregex = /<[^>]*(src|href)=\s*(.?)([^>\s]*)\2[^>]*>\s*/i
  while linkregex.match(text)
    links << $~[3]
    text.sub!(linkregex, "[#{links.size}]")
  end

  text = CGI.unescapeHTML(
    text.
      gsub(/<(script|style)[^>]*>.*<\/\1>/im, '').
      gsub(/<!--.*-->/m, '').
      gsub(/<hr(| [^>]*)>/i, "___\n").
      gsub(/<li(| [^>]*)>/i, "\n* ").
      gsub(/<blockquote(| [^>]*)>/i, '> ').
      gsub(/<(br)(| [^>]*)>/i, "\n").
      gsub(/<(\/h[\d]+|p)(| [^>]*)>/i, "\n\n").
      gsub(/<[^>]*>/, '')
  ).lstrip.gsub(/\n[ ]+/, "\n") + "\n"

  for i in (0...links.size).to_a
    text = text + "\n  [#{i+1}] <#{CGI.unescapeHTML(links[i])}>" unless links[i].nil?
  end
  links = nil
  text
end
