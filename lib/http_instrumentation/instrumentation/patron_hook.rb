# frozen_string_literal: true

module HTTPInstrumentation
  module Instrumentation
    module PatronHook
      class << self
        def instrument!
          Instrumentation.instrument!(::Patron::Session, self) if defined?(::Patron::Session)
        end
      end

      private

      def request(action, url, *args)
        HTTPInstrumentation.instrument("patron") do |payload|
          response = super

          payload[:http_method] = action
          payload[:url] = url
          payload[:status_code] = response.status

          response
        end
      end
    end
  end
end
