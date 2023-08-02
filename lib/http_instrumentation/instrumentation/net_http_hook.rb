# frozen_string_literal: true

begin
  require "net/http"
rescue LoadError
end

module HTTPInstrumentation
  module Instrumentation
    # This module is responsible for instrumenting the net/http module in the standard library.
    module NetHTTPHook
      class << self
        def instrument!
          Instrumentation.instrument!(::Net::HTTP, self, :request) if defined?(::Net::HTTP)
        end

        def installed?
          !!(defined?(::Net::HTTP) && ::Net::HTTP.include?(self))
        end

        attr_accessor :aliased
      end

      def request(req, *args, &block)
        unless started?
          if HTTPInstrumentation::Instrumentation::NetHTTPHook.aliased
            return request_without_http_instrumentation(req, *args, &block)
          else
            return super
          end
        end

        HTTPInstrumentation.instrument("net/http") do |payload|
          response = if HTTPInstrumentation::Instrumentation::NetHTTPHook.aliased
            request_without_http_instrumentation(req, *args, &block)
          else
            super
          end

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
