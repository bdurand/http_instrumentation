# frozen_string_literal: true

begin
  require "http"
rescue LoadError
end

module HTTPInstrumentation
  module Instrumentation
    # This module is responsible for instrumenting the http gem.
    module HTTPHook
      class << self
        def instrument!
          Instrumentation.instrument!(::HTTP::Client, self) if defined?(::HTTP::Client)
        end

        def installed?
          !!(defined?(::HTTP::Client) && ::HTTP::Client.include?(self))
        end
      end

      def perform(request, *args)
        HTTPInstrumentation.instrument("http") do |payload|
          response = super

          payload[:http_method] = request.verb
          payload[:url] = request.uri
          payload[:status_code] = response.status

          response
        end
      end
    end
  end
end
