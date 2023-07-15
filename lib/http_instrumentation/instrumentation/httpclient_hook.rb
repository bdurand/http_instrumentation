# frozen_string_literal: true

begin
  require "httpclient"
rescue LoadError
end

module HTTPInstrumentation
  module Instrumentation
    module HTTPClientHook
      # This module is responsible for instrumenting the httpclient gem.
      class << self
        def instrument!
          Instrumentation.instrument!(::HTTPClient, self) if defined?(::HTTPClient)
        end

        def installed?
          !!(defined?(::HTTPClient) && ::HTTPClient.include?(self))
        end
      end

      def do_get_block(request, *)
        HTTPInstrumentation.instrument("httpclient") do |payload|
          response = super

          begin
            payload[:http_method] = request.header.request_method
            payload[:url] = request.header.request_uri
            payload[:status_code] = response.header.status_code
          rescue
          end

          response
        end
      end
    end
  end
end
