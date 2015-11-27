module Kawaii
  # Allows handlers to use methods defined in outer contexts or at class scope.
  # Set {#parent_scope} in constructor.
  module MethodChain
    attr_writer :parent_scope

    def method_missing(meth, *args)
      @parent_scope.send(meth, *args) if @parent_scope.respond_to?(meth)
    end

    def respond_to?(method_name, include_private = false)
      super || @parent_scope.respond_to?(method_name, include_private)
    end
  end
end
