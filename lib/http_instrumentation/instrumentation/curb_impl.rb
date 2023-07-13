# frozen_string_literal: true

module HTTPInstrumentation
  module Instrumentation
    module CurbImpl
      class << self
        def instrument!
          Instrumentation.instrument!(::Curl::Easy, self) if defined?(::Curl::Easy)
        end
      end

      def http(method, *args)
        retval = nil

        payload = {method: Instrumentation.normalize_http_method(method), url: url.to_s, client: "curb"}

        ActiveSupport::Notifications.instrument("request.http", payload) do
          retval = super
          payload[:status] = status&.to_i
        end

        retval
      end
    end
  end
end
