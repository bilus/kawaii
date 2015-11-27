module Kawaii
  # @private
  # Maps route to a handler based on parameters.
  # Supports mapping to blocks and to controller actions.
  class RouteMapping
    def initialize(mapping, &block)
      fail 'Do not provide a block if mapping given' if mapping && block
      fail 'Provide a mapping or a block' unless mapping || block
      @mapping = mapping
      @block = block
    end

    def resolve
      return @block if @block
      controller_name, method = parse(@mapping)
      controller_class = find_controller(controller_name)
      fail "Cannot find controller: #{controller_name}" if controller_class.nil?
      proc do |& _args|
        controller = controller_class.new(params, request)
        controller.send(method)
      end
    end

    protected

    def find_controller(controller_name)
      Object.const_get(controller_name)
    end

    def parse(mapping)
      controller, method = mapping.split('#')
      [controller.camelcase, method.to_sym]
    end
  end
end
