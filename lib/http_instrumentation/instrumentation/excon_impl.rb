# frozen_string_literal: true

module HTTPInstrumentation
  module Instrumentation
    module ExconImpl
      class << self
        def instrument!
          Instrumentation.instrument!(::Excon::Connection, self) if defined?(::Excon::Connection)
        end
      end

      def request(params = {}, *args)
        response = nil

        options = data.merge(params)
        method = (options[:method] || :get)
        default_port = ((options[:scheme]&.downcase == "https") ? 443 : 80)
        url = "#{options[:scheme]}://#{options[:host]}:#{options[:port] unless options[:port] == default_port}#{options[:path]}"
        payload = {method: Instrumentation.normalize_http_method(method), url: url.to_s, client: "excon"}

        ActiveSupport::Notifications.instrument("request.http", payload) do
          response = super
          payload[:status] = response.status&.to_i
        end

        response
      end
    end
  end
end
