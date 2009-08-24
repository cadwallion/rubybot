class RubyBot
  def setup_defaults
    self.add_handler('privmsg', IRCHandler.message_handler)
  end
end
