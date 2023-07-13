# frozen_string_literal: true

module HTTPInstrumentation
  module Instrumentation
    module HTTPClientImpl
      class << self
        def instrument!
          Instrumentation.instrument!(::HTTPClient, self) if defined?(::HTTPClient)
        end
      end

      def do_get_block(request, *args)
        response = nil

        header = request.header
        payload = {method: Instrumentation.normalize_http_method(header.request_method), url: header.request_uri&.to_s, client: "httpclient"}

        ActiveSupport::Notifications.instrument("request.http", payload) do
          response = super
          payload[:status] = response.header.status_code
        end

        response
      end
    end
  end
end
