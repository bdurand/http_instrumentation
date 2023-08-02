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
          Instrumentation.instrument!(::HTTP::Client, self, :perform) if defined?(::HTTP::Client)
        end

        def installed?
          !!(defined?(::HTTP::Client) && ::HTTP::Client.include?(self))
        end

        attr_accessor :aliased
      end

      def perform(request, *args)
        HTTPInstrumentation.instrument("http") do |payload|
          response = if HTTPInstrumentation::Instrumentation::HTTPHook.aliased
            perform_without_http_instrumentation(request, *args)
          else
            super
          end

          begin
            payload[:http_method] = request.verb
            payload[:url] = request.uri
            payload[:status_code] = response.status
          rescue
          end

          response
        end
      end
    end
  end
end
