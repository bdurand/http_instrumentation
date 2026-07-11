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
    # Lock to prevent concurrent calls from installing the same hooks twice;
    # double aliasing would point the _without_http_instrumentation method at
    # the instrumented method itself, causing infinite recursion.
    INSTRUMENT_LOCK = Mutex.new
    private_constant :INSTRUMENT_LOCK

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
        INSTRUMENT_LOCK.synchronize do
          return if klass.include?(instrumentation_module)

          methods = Array(methods).collect(&:to_sym)

          if HTTPInstrumentation.force_prepend? || methods_defined_in_module?(klass, methods)
            klass.prepend(instrumentation_module)
            instrumentation_module.aliased = false
          else
            methods.each do |method|
              instrumentation_module.alias_method("#{method}_with_http_instrumentation", method)
            end

            klass.include(instrumentation_module)

            swap_methods = methods.reject { |method| defines_method?(klass, "#{method}_without_http_instrumentation") }

            swap_methods.each do |method|
              klass.alias_method("#{method}_without_http_instrumentation", method)
            end

            # The aliased flag must be set before the instrumented methods are
            # swapped in; a call landing in between would take the super branch
            # and raise NoMethodError since the module was included, not prepended.
            instrumentation_module.aliased = true

            swap_methods.each do |method|
              klass.alias_method(method, "#{method}_with_http_instrumentation")
            end
          end
        end
      end

      private

      # Returns true if any of the methods are defined in a module in the class's
      # ancestry rather than directly on the class itself. This covers both modules
      # prepended in front of the class and modules included behind it. In either
      # case the aliasing strategy cannot be used: including the instrumentation
      # module would insert it ahead of the module that defines the method, so
      # aliasing the method afterward would capture the instrumented method itself
      # and cause infinite recursion.
      def methods_defined_in_module?(klass, methods)
        defined_in_module = false

        klass.ancestors.each do |mod|
          next unless mod.is_a?(Module) && !mod.is_a?(Class)

          module_methods = mod.instance_methods(false) + mod.private_instance_methods(false)
          defined_in_module = (module_methods & methods).any?
          break if defined_in_module
        end

        defined_in_module
      end

      def defines_method?(klass, method)
        klass.method_defined?(method) || klass.private_method_defined?(method)
      end
    end
  end
end
