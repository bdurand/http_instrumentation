# frozen_string_literal: true

module HTTPInstrumentation
  module Instrumentation
    module HTTPHook
      class << self
        def instrument!
          Instrumentation.instrument!(::HTTP::Client, self) if defined?(::HTTP::Client)
        end
      end

      def perform(request, *args)
        HTTPInstrumentation.instrument("http") do |payload|
          response = super

          payload[:method] = request.verb
          payload[:url] = request.uri
          payload[:status] = response.status

          response
        end
      end
    end
  end
end
