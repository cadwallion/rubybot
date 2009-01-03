class TranslateModule
  def self.garble(args, event)
    num = rand(6) + 4
    last = "en"
    last_result = args
    langs = []
    1.upto(num) do
      to = TRANSLATE_LANGS[rand(TRANSLATE_LANGS.size - 1)]
      last_result = do_translate(last,to,last_result)
      last = to
      langs << to
    end
    last_result = do_translate(last,"en",last_result)
    return "Garbled '#{args}', went from en => #{langs.join(" => ")} => en and got '#{last_result}'"
  end
  def self.translate(args, event)
    args = args.split(' ',3)
    return do_translate(args[0], args[1], args[2])
  end
  def self.do_translate(from,to,phrase)
    url = URI.parse("http://translate.google.com/translate_t?sl=#{URI.encode(from)}&tl=#{URI.encode(to)}&text=#{URI.encode(phrase)}").to_s
    result = RemoteRequest.new("get").read(url)
    doc = Hpricot(result)
    return (doc/"#result_box").inner_html
  end
end

if !defined?(TRANSLATE_LANGS)
  TRANSLATE_LANGS = ['ar', 'bg', 'ca', 'zh-CN', 'hr', 'cs', 'da', 'nl', 'en', 'tl', 'fi', 'fr', 'de', 'el', 'iw', 'hi', 'id', 'it', 'ja', 'ko', 'lv', 'lt', 'no', 'pl', 'pt', 'ro', 'ru', 'sr', 'sk', 'sl', 'es', 'sv', 'uk', 'vi']
end
