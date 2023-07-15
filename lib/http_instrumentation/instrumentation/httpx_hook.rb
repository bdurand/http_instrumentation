# frozen_string_literal: true

begin
  require "httpx"
rescue LoadError
end

module HTTPInstrumentation
  module Instrumentation
    # This module is responsible for instrumenting the httpx gem.
    module HTTPXHook
      class << self
        def instrument!
          Instrumentation.instrument!(::HTTPX::Session, self) if defined?(::HTTPX::Session)
        end

        def installed?
          !!(defined?(::HTTPX::Session) && ::HTTPX::Session.include?(self))
        end
      end

      private

      def send_requests(*requests)
        HTTPInstrumentation.instrument("httpx") do |payload|
          responses = super

          if requests.size == 1
            begin
              payload[:http_method] = requests.first.verb
              payload[:url] = requests.first.uri
              payload[:status_code] = responses.first.status
            rescue
            end
          else
            payload[:count] = requests.size
          end

          responses
        end
      end
    end
  end
end
