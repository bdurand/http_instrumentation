# frozen_string_literal: true

begin
  require "curb"
rescue LoadError
end

module HTTPInstrumentation
  module Instrumentation
    # This module is responsible for instrumenting the curb gem.
    module CurbHook
      class << self
        def instrument!
          Instrumentation.instrument!(::Curl::Easy, self) if defined?(::Curl::Easy)
        end

        def installed?
          !!(defined?(::Curl::Easy) && ::Curl::Easy.include?(self))
        end
      end

      def http(method, *args)
        HTTPInstrumentation.instrument("curb") do |payload|
          retval = super

          payload[:http_method] = method
          payload[:url] = url
          payload[:status_code] = response_code

          retval
        end
      end
    end
  end
end
