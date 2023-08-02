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
          Instrumentation.instrument!(::Typhoeus::Request, Easy, :run) if defined?(::Typhoeus::Request)
          Instrumentation.instrument!(::Typhoeus::Hydra, Multi, :run) if defined?(::Typhoeus::Hydra)
        end

        def installed?
          !!(
            defined?(::Typhoeus::Request) && ::Typhoeus::Request.include?(Easy) &&
            defined?(::Typhoeus::Hydra) && ::Typhoeus::Hydra.include?(Multi)
          )
        end
      end

      module Multi
        class << self
          attr_accessor :aliased
        end

        def run(*args)
          HTTPInstrumentation.instrument("typhoeus") do |payload|
            begin
              payload[:count] = queued_requests.size
            rescue
            end

            if HTTPInstrumentation::Instrumentation::TyphoeusHook::Multi.aliased
              run_without_http_instrumentation(*args)
            else
              super
            end
          end
        end
      end

      module Easy
        class << self
          attr_accessor :aliased
        end

        def run(*args)
          HTTPInstrumentation.instrument("typhoeus") do |payload|
            retval = if HTTPInstrumentation::Instrumentation::TyphoeusHook::Easy.aliased
              run_without_http_instrumentation(*args)
            else
              super
            end

            begin
              payload[:http_method] = options[:method]
              payload[:url] = url
              payload[:status_code] = response&.response_code
            rescue
            end

            retval
          end
        end
      end
    end
  end
end
