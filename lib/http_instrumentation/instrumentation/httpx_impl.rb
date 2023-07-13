# frozen_string_literal: true

module HTTPInstrumentation
  module Instrumentation
    module HTTPXImpl
      class << self
        def instrument!
          Instrumentation.instrument!(::HTTPX::Session, self) if defined?(::HTTPX::Session)
        end
      end

      private

      def send_requests(*requests)
        responses = nil

        payload = {client: "httpx"}
        if requests.size == 1
          request = requests.first
          payload[:method] = Instrumentation.normalize_http_method(request.verb)
          payload[:url] = request.uri&.to_s
        else
          payload[:count] = requests.size
        end

        ActiveSupport::Notifications.instrument("request.http", payload) do
          responses = super
          payload[:status] = responses.first.status if responses.size == 1
        end

        responses
      end
    end
  end
end
