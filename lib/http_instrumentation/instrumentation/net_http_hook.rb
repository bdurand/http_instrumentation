# frozen_string_literal: true

module HTTPInstrumentation
  module Instrumentation
    module NetHTTPHook
      class << self
        def instrument!
          Instrumentation.instrument!(::Net::HTTP, self) if defined?(::Net::HTTP)
        end
      end

      def request(request, *args)
        HTTPInstrumentation.instrument("net/http") do |payload|
          response = super

          payload[:method] = request.method
          payload[:url] = request.uri
          payload[:status] = response.code

          response
        end
      end
    end
  end
end
