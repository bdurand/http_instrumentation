# frozen_string_literal: true

begin
  require "patron"
rescue LoadError
end

module HTTPInstrumentation
  module Instrumentation
    # This module is responsible for instrumenting the patron gem.
    module PatronHook
      class << self
        def instrument!
          Instrumentation.instrument!(::Patron::Session, self) if defined?(::Patron::Session)
        end

        def installed?
          !!(defined?(::Patron::Session) && ::Patron::Session.include?(self))
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
