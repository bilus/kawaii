# Extend String class.
class String
  def camelcase
    gsub(/(?<=_|^)(\w)/) { Regexp.last_match[1].upcase }.gsub(/(?:_)(\w)/, '\1')
  end
end
