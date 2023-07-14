# frozen_string_literal: true

module HTTPInstrumentation
  module Instrumentation
    module HTTPXHook
      class << self
        def instrument!
          Instrumentation.instrument!(::HTTPX::Session, self) if defined?(::HTTPX::Session)
        end
      end

      private

      def send_requests(*requests)
        HTTPInstrumentation.instrument("httpx") do |payload|
          responses = super

          if requests.size == 1
            payload[:http_method] = requests.first.verb
            payload[:url] = requests.first.uri
            payload[:status_code] = responses.first.status
          else
            payload[:count] = requests.size
          end

          responses
        end
      end
    end
  end
end
