# frozen_string_literal: true

module HTTPInstrumentation
  module Instrumentation
    module NetHTTPImpl
      class << self
        def instrument!
          Instrumentation.instrument!(::Net::HTTP, self) if defined?(::Net::HTTP)
        end
      end

      def request(request, *args)
        response = nil

        payload = {method: Instrumentation.normalize_http_method(request.method), url: request.uri&.to_s, client: "net/http"}

        ActiveSupport::Notifications.instrument("request.http", payload) do
          response = super
          payload[:status] = response.code&.to_i
        end

        response
      end
    end
  end
end
