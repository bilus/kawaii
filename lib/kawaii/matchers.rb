# Route matchers.
module Kawaii
  # Result of matching a path.
  class Match
    # What is left of the actual path after {Matcher#match} consumed the
    # matching portion.
    attr_reader :remaining_path
    # Hash containing params extracted from paths such as
    # /users/:user_id/posts/:post_id
    attr_reader :params

    # Creates a new match result.
    # @param remaining_path [String] what is left of the actual path after
    #        {Matcher#match} consumed the matching portion
    # @param params [Hash] params extracted from paths such as /users/:id
    def initialize(remaining_path, params = {})
      @remaining_path = remaining_path
      @params = params
    end
  end

  # @abstract Base class for a route matcher.
  class Matcher
    # Creates a matcher.
    # @param path [String, Regexp, Matcher] path specification to compile
    #        to a matcher
    # @param options [Hash] :full_match to require the entire path to match
    #        the resulting matcher
    # Generated matchers by default match only the beginning of the string
    # containing the actual path from Rack environment.
    def self.compile(path, options = {})
      # @todo Make it extendable?
      matcher = if path.is_a?(String)
                  StringMatcher.new(path)
                elsif path.is_a?(Regexp)
                  RegexpMatcher.new(path)
                elsif path.is_a?(Matcher)
                  path
                else
                  fail RuntimeException, "#{path} is not a supported matcher"
                end
      options[:full_match] ? FullMatcher.new(matcher) : matcher
    end

    # Tries to match the actual path.
    # @param path [String] the actual path from Rack env
    # @return {Match} if the beginning of path does match or nil if there is
    # no match.
    def match(_path)
      fail NotImplementedError
    end
  end

  # Matcher for string paths. Supports named params.
  #
  # @example Simple string matcher
  #   get '/users' do ... end
  #
  # @example Named parameters
  #   get '/users/:id' do ... end
  #
  # @example Wildcards
  #   get '/users/?' do ... end # Optional trailing slash
  class StringMatcher
    # Creates a {StringMatcher}
    # @param path [String] path specification
    def initialize(path)
      @rx = compile(path)
    end

    # Tries to match the actual path.
    # @param path [String] the actual path from Rack env
    # @return {Match} if the beginning of path does match or nil if there
    # is no match.
    def match(path)
      m = path.match(@rx)
      Match.new(remaining_path(path, m), match_to_params(m)) if m
    end

    protected

    def compile(path)
      prep_path = path.gsub('*', '.*').gsub(%r{/\:([^/]+)}, '/(?<\1>[^\/]+)')
      Regexp.new("^#{prep_path}")
    end

    def remaining_path(path, m)
      _, start = m.offset(0) # Whole match.
      path[start..-1]
    end

    def match_to_params(m)
      # In-place reduce:
      m.names.each_with_object({}) { |n, params| params[n.to_sym] = m[n] }
    end
  end

  # Regular expression matcher.
  # @example Simple regular expression matcher
  #   get /\/users.*/ do ... end
  class RegexpMatcher
    # Creates a {RegexpMatcher}
    # @param path [Regexp] path specification regex
    # @todo Support parameters based on named capture groups.
    def initialize(rx)
      @rx = rx
    end

    # Tries to match the actual path.
    # @param path [String] the actual path from Rack env
    # @return {Match} if the beginning of path does match or nil if there is
    # no match.
    def match(path)
      new_path = path.gsub(@rx, '')
      Match.new(new_path) if path != new_path
    end
  end

  # Ensures the entire path is consumed by the wrapped {Matcher} instance.
  class FullMatcher
    # Creates a {FullMatcher}.
    # @param matcher [Matcher] wrapped matcher
    def initialize(matcher)
      @matcher = matcher
    end

    # Tries to match the entire actual path.
    # @param path [String] the actual path from Rack env
    # @return {Match} if the entire path does match or nil otherwise.
    def match(path)
      m = @matcher.match(path)
      m if m && m.remaining_path == ''
    end
  end
end
