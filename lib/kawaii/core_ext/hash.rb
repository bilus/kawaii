# Extend {Hash}.
class Hash
  # Transforms keys.
  #
  # @yield [key] gives each key to the block
  # @yieldreturn [key] new key
  #
  # @return [Hash] new hash with transformed keys
  def update_keys
    result = self.class.new
    each_key do |key|
      result[yield(key)] = self[key]
    end
    result
  end

  # Turns string keys to symbols.
  #
  # @return [Hash] a new hash
  def symbolize_keys
    update_keys(&:to_sym)
  end
end
