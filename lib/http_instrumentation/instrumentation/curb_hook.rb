# frozen_string_literal: true

module HTTPInstrumentation
  module Instrumentation
    module CurbHook
      class << self
        def instrument!
          Instrumentation.instrument!(::Curl::Easy, self) if defined?(::Curl::Easy)
        end
      end

      def http(method, *args)
        HTTPInstrumentation.instrument("curb") do |payload|
          retval = super

          payload[:method] = method
          payload[:url] = url
          payload[:status] = status

          retval
        end
      end
    end
  end
end