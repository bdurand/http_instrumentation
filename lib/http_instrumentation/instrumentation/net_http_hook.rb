# frozen_string_literal: true

module HTTPInstrumentation
  module Instrumentation
    module NetHTTPHook
      class << self
        def instrument!
          Instrumentation.instrument!(::Net::HTTP, self) if defined?(::Net::HTTP)
        end
      end

      def request(req, *args)
        return super unless started?

        HTTPInstrumentation.instrument("net/http") do |payload|
          response = super

          default_port = (use_ssl? ? 443 : 80)
          scheme = (use_ssl? ? "https" : "http")
          url = "#{scheme}://#{address}#{":#{port}" unless port == default_port}#{req.path}"
          payload[:http_method] = req.method
          payload[:url] = url
          payload[:status_code] = response.code

          response
        end
      end
    end
  end
end
