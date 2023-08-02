# frozen_string_literal: true

require_relative "instrumentation/curb_hook"
require_relative "instrumentation/ethon_hook"
require_relative "instrumentation/excon_hook"
require_relative "instrumentation/httpclient_hook"
require_relative "instrumentation/http_hook"
require_relative "instrumentation/httpx_hook"
require_relative "instrumentation/net_http_hook"
require_relative "instrumentation/patron_hook"
require_relative "instrumentation/typhoeus_hook"

module HTTPInstrumentation
  module Instrumentation
    class << self
      # Helper method to add an instrumentation module to methods on a class. The
      # methods must be defined in the instrumentation module.
      #
      # If the methods have already been prepended on the class, then module will
      # be prepended to the class. Otherwise, the methods will be aliased and the
      # module will be included in the class. This is because prepending and aliasing
      # methods are not compatible with each other and other instrumentation libraries
      # may have already prepended the methods. Aliasing is the default strategy because
      # prepending after aliasing will work, but aliasing after prepending will not.
      def instrument!(klass, instrumentation_module, methods)
        return if klass.include?(instrumentation_module)

        methods = Array(methods).collect(&:to_sym)

        if methods_prepended?(klass, methods)
          klass.prepend(instrumentation_module)
          instrumentation_module.aliased = false
        else
          Array(methods).each do |method|
            instrumentation_module.alias_method("#{method}_with_http_instrumentation", method)
          end

          klass.include(instrumentation_module)

          Array(methods).each do |method|
            klass.alias_method("#{method}_without_http_instrumentation", method)
            klass.alias_method(method, "#{method}_with_http_instrumentation")
          end

          instrumentation_module.aliased = true
        end
      end

      private

      def methods_prepended?(klass, methods)
        prepended = false

        klass.ancestors.each do |mod|
          next unless mod.is_a?(Module) && !mod.is_a?(Class)

          module_methods = mod.instance_methods(false) + mod.private_instance_methods(false)
          prepended = (module_methods & methods).any?
          break if prepended
        end

        prepended
      end
    end
  end
end
