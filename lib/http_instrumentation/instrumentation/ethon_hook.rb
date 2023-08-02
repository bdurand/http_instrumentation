# frozen_string_literal: true

begin
  require "ethon"
rescue LoadError
end

module HTTPInstrumentation
  module Instrumentation
    # This module is responsible for instrumenting the ethon gem.
    module EthonHook
      class << self
        def instrument!
          Instrumentation.instrument!(::Ethon::Easy, Easy, [:http_request, :perform]) if defined?(::Ethon::Easy)
          Instrumentation.instrument!(::Ethon::Multi, Multi, :perform) if defined?(::Ethon::Multi)
        end

        def installed?
          !!(
            defined?(::Ethon::Easy) && ::Ethon::Easy.include?(Easy) &&
            defined?(::Ethon::Multi) && ::Ethon::Multi.include?(Multi)
          )
        end
      end

      module Multi
        class << self
          attr_accessor :aliased
        end

        def perform(*args)
          HTTPInstrumentation.instrument("ethon") do |payload|
            begin
              payload[:count] = easy_handles.size
            rescue
            end

            if HTTPInstrumentation::Instrumentation::EthonHook::Multi.aliased
              perform_without_http_instrumentation(*args)
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

        def http_request(url, action_name, *args)
          @http_instrumentation_method = action_name
          @http_instrumentation_url = url
          if HTTPInstrumentation::Instrumentation::EthonHook::Easy.aliased
            http_request_without_http_instrumentation(url, action_name, *args)
          else
            super
          end
        end

        def perform(*args)
          HTTPInstrumentation.instrument("ethon") do |payload|
            retval = if HTTPInstrumentation::Instrumentation::EthonHook::Easy.aliased
              perform_without_http_instrumentation(*args)
            else
              super
            end

            payload[:http_method] = @http_instrumentation_method
            payload[:url] = @http_instrumentation_url
            begin
              payload[:status_code] = response_code
            rescue
            end

            retval
          end
        end
      end
    end
  end
end
