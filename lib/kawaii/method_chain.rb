module Kawaii
  # Allows handlers to use methods defined in outer contexts or at class scope.
  # Set {#parent_scope} in constructor.
  module MethodChain
    attr_writer :parent_scope
      
    def method_missing(meth, *args)
      # puts "method_missing? #{self} #{meth} #{@parent_scope} #{@parent_scope.respond_to?(meth)}"
      if @parent_scope.respond_to?(meth)
        @parent_scope.send(meth, *args)
      end
    end

    def respond_to?(method_name, include_private = false)
      # puts "respond_to? #{self} #{method_name} #{@parent_scope} #{@parent_scope.respond_to?(method_name, include_private)}"
      super || @parent_scope.respond_to?(method_name, include_private)
    end
  end
end
