# frozen_string_literal: true

module HTTPInstrumentation
  module Instrumentation
    module PatronImpl
      class << self
        def instrument!
          Instrumentation.instrument!(::Patron::Session, self) if defined?(::Patron::Session)
        end
      end

      private

      def request(action, url, *args)
        response = nil

        payload = {method: Instrumentation.normalize_http_method(action), url: url.to_s, client: "patron"}

        ActiveSupport::Notifications.instrument("request.http", payload) do
          response = super
          payload[:status] = response.status
        end

        response
      end
    end
  end
end
