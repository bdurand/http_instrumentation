# frozen_string_literal: true

module HTTPInstrumentation
  module Instrumentation
    module ExconHook
      class << self
        def instrument!
          Instrumentation.instrument!(::Excon::Connection, self) if defined?(::Excon::Connection)
        end
      end

      def request(params = {}, *args)
        HTTPInstrumentation.instrument("excon") do |payload|
          response = super

          scheme = response.scheme&.downcase
          default_port = ((scheme == "https") ? 443 : 80)
          payload[:http_method] = response.http_method
          payload[:url] = "#{scheme}://#{response.host}#{":#{response.port}" unless response.port == default_port}#{response.path}#{"?#{response.query}" unless response.query.to_s.empty?}"
          payload[:status_code] = response.status

          response
        end
      end
    end
  end
end
