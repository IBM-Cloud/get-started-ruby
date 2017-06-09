class AntiXSS
  def self.sanitize_input(str)
    String(str).gsub(/&(?!amp;|lt;|gt;)/, '&amp;').gsub(/</, '&lt;').gsub(/>/, '&gt;')
  end
end
