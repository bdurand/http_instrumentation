# frozen_string_literal: true

module HTTPInstrumentation
  module Instrumentation
    module HTTPImpl
      class << self
        def instrument!
          Instrumentation.instrument!(::HTTP::Client, self) if defined?(::HTTP::Client)
        end
      end

      def perform(request, *args)
        response = nil

        payload = {method: Instrumentation.normalize_http_method(request.verb), url: request.uri&.to_s, client: "http"}

        ActiveSupport::Notifications.instrument("request.http", payload) do
          response = super
          payload[:status] = response.status&.to_i
        end

        response
      end
    end
  end
end
