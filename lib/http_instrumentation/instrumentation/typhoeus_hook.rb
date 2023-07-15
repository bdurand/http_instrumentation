# frozen_string_literal: true

begin
  require "typhoeus"
rescue LoadError
end

module HTTPInstrumentation
  module Instrumentation
    # This module is responsible for instrumenting the typhoeus gem.
    module TyphoeusHook
      class << self
        def instrument!
          Instrumentation.instrument!(::Typhoeus::Request, Easy) if defined?(::Typhoeus::Request)
          Instrumentation.instrument!(::Typhoeus::Hydra, Multi) if defined?(::Typhoeus::Hydra)
        end

        def installed?
          !!(
            defined?(::Typhoeus::Request) && ::Typhoeus::Request.include?(Easy) &&
            defined?(::Typhoeus::Hydra) && ::Typhoeus::Hydra.include?(Multi)
          )
        end
      end

      module Multi
        def run(*)
          HTTPInstrumentation.instrument("typhoeus") do |payload|
            payload[:count] = queued_requests.size

            super
          end
        end
      end

      module Easy
        def run(*)
          HTTPInstrumentation.instrument("typhoeus") do |payload|
            retval = super

            payload[:http_method] = options[:method]
            payload[:url] = url
            payload[:status_code] = response&.response_code

            retval
          end
        end
      end
    end
  end
end
