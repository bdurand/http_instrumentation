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
          Instrumentation.instrument!(::Patron::Session, self, :request) if defined?(::Patron::Session)
        end

        def installed?
          !!(defined?(::Patron::Session) && ::Patron::Session.include?(self))
        end

        attr_accessor :aliased
      end

      private

      def request(action, url, *args)
        HTTPInstrumentation.instrument("patron") do |payload|
          response = if HTTPInstrumentation::Instrumentation::PatronHook.aliased
            request_without_http_instrumentation(action, url, *args)
          else
            super
          end

          payload[:http_method] = action
          payload[:url] = url
          begin
            payload[:status_code] = response.status
          rescue
          end

          response
        end
      end
    end
  end
end
