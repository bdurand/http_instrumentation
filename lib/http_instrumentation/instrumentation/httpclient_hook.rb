# frozen_string_literal: true

module HTTPInstrumentation
  module Instrumentation
    module HTTPClientHook
      class << self
        def instrument!
          Instrumentation.instrument!(::HTTPClient, self) if defined?(::HTTPClient)
        end
      end

      def do_get_block(request, *args)
        HTTPInstrumentation.instrument("httpclient") do |payload|
          response = super

          payload[:http_method] = request.header.request_method
          payload[:url] = request.header.request_uri
          payload[:status_code] = response.header.status_code

          response
        end
      end
    end
  end
end
