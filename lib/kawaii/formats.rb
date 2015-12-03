# MIME formats.
module Kawaii
  # Registered formats.
  class FormatRegistry
    @formats = {}
    class << self
      attr_accessor :formats
    end

    # Registers a new format. Formats are preferred in the order they are
    # registered; the first format has the highest priority.
    def self.register!(format)
      @formats[format.key] = format
    end
  end

  # Core format-handling class.
  class FormatHandler
    # Creates a format handler for a route handler
    # @param [Kawaii::RouteHandler] current route handler
    # @return {FormatHandler}
    def initialize(route_handler)
      @route_handler = route_handler
      @candidates = []
      @blocks = {}
    end

    # Matches method invoked in end-user code with {FormatBase#key}.
    # If format matches the current request, it saves it for negotiation
    # in {FormatHandler#response}.
    def method_missing(meth, *_args, &block)
      format = FormatRegistry.formats[meth]
      return unless format && format.match?(@route_handler.request)
      @candidates << format
      @blocks[meth] = block
    end

    # Encoded response based on matched format (see
    # {FormatHandler#method_missing}).
    # @return {Array} Rack response array or nil if no format was matched
    def response
      format, block = find_best_match
      return if format.nil?
      # @note Request is mutated here!
      new_params = format.parse_params(@route_handler.request)
      @route_handler.params.merge!(new_params) if new_params
      response = @route_handler.instance_exec(&block)
      format.encode(response)
    end

    protected

    def find_best_match
      # Find matching format trying to match the first registered format
      # then the second one and so on.
      registered_fmts = FormatRegistry.formats
      _, format = registered_fmts.find { |_, fmt| @candidates.include?(fmt) }
      [format, @blocks[format.key]] if format
    end
  end

  # @abstract Base class for MIME format handlers.
  class FormatBase
    # Unique key for the format and at the same time the name of the method used
    # in end-user-code to define format handler.
    #
    # @example Format handler for :json key
    #   respond_to do |format|
    #     format.json { ... }
    #   end
    def key
      fail NotImplementedError
    end

    # Returns true if the format is compatible with the request.
    # @param _request [Rack::Request] current HTTP request
    # @return true if there's a match.
    def match?(_request)
      fail NotImplementedError
    end

    # Parses params in request body in a way specific to the given format.
    # @param _request [Rack::Request] contains information about the current
    # HTTP request
    # @return {Hash} including parsed params or nil
    def parse_params(_request)
      # Optional.
    end

    # Encodes response appropriately for the given format.
    # @param _response [String, Hash, Array] response from format handler block.
    # @return Rack response {Array}
    def encode(_response)
      fail NotImplementedError
    end
  end

  require 'json'

  # JSON MIME format (application/json).
  class JsonFormat < FormatBase
    # Unique key for the format and at the same time the name of the method used
    # in end-user-code to define format handler.
    #
    # @example Format handler for :json key
    #   respond_to do |format|
    #     format.json do
    #       { foo: 'bar' }
    #     end
    #   end
    def key
      :json
    end

    # Returns true if the format is compatible with the request.
    # @param request [Rack::Request] current HTTP request
    # @return true if there's a match.
    def match?(request)
      request.content_type =~ %r{^application/json.*}
    end

    # Parses JSON string in request body if present and converts it to a hash.
    # @param request [Rack::Request] contains information about the current HTTP
    #        request
    # @return {Hash} including parsed params or nil
    def parse_params(request)
      json = request.body.read
      JSON.parse(json).symbolize_keys if json.is_a?(String) && !json.empty?
    end

    # Encodes response appropriately by converting it to a JSON string.
    # @param response [String, Hash, Array] response from format handler block.
    # @return Rack response {Array}
    def encode(response)
      json = response.to_json
      [200,
       { Rack::CONTENT_TYPE => 'application/json',
         Rack::CONTENT_LENGTH => json.length.to_s },
       [json]]
    end
  end

  # HTML MIME format.
  class HtmlFormat < FormatBase
    # Unique key for the format and at the same time the name of the method used
    # in end-user-code to define format handler.
    #
    # @example Format handler for :html key
    #   respond_to do |format|
    #     format.html { 'Hello, world' }
    #   end
    def key
      :html
    end

    # Always matches. This is why this format needs to be the last to
    # be registered so more specific formats are before it.
    def match?(_request)
      true
    end

    # Response with text/html response.
    # @param response [String] response from format handler block.
    # @return Rack response {Array}
    def encode(response)
      [200,
       { Rack::CONTENT_TYPE => 'text/html',
         Rack::CONTENT_LENGTH => response.size.to_s },
       [response]]
    end
  end

  # Include this module to support 'respond_to'.
  module FormatMethods
    def respond_to(&block)
      format_handler = FormatHandler.new(self)
      instance_exec(format_handler, &block)
      format_handler.response
    end
  end

  # Register supported MIME formats.
  FormatRegistry.register!(JsonFormat.new)
  FormatRegistry.register!(HtmlFormat.new)
end
