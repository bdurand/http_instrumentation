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

      def http(method, *)
        HTTPInstrumentation.instrument("curb") do |payload|
          retval = super

          payload[:http_method] = method
          begin
            payload[:url] = url
            payload[:status_code] = response_code
          rescue
          end

          retval
        end
      end
    end
  end
end
