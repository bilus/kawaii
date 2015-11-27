module Kawaii
  # @private
  # Maps route to a handler based on parameters.
  # Supports mapping to blocks and to controller actions.
  class RouteMapping
    def initialize(mapping, &block)
      raise RuntimeError 'Do not provide a block if mapping given' if mapping && block
      raise RuntimeError, 'Provide a mapping or a block' unless mapping || block
      @mapping = mapping
      @block = block
    end
    
    def resolve
      return @block if @block
      controller_name, method = parse(@mapping)
      controller_class = find_controller(controller_name) or raise RuntimeError, "Cannot find controller: #{controller_class}"
      Proc.new do |& _args|
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
