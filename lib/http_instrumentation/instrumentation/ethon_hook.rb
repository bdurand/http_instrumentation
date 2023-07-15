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
          Instrumentation.instrument!(::Ethon::Easy, Easy) if defined?(::Ethon::Easy)
          Instrumentation.instrument!(::Ethon::Multi, Multi) if defined?(::Ethon::Multi)
        end

        def installed?
          !!(
            defined?(::Ethon::Easy) && ::Ethon::Easy.include?(Easy) &&
            defined?(::Ethon::Multi) && ::Ethon::Multi.include?(Multi)
          )
        end
      end

      module Multi
        def perform(*)
          HTTPInstrumentation.instrument("ethon") do |payload|
            begin
              payload[:count] = easy_handles.size
            rescue
            end

            super
          end
        end
      end

      module Easy
        def http_request(url, action_name, *)
          @http_method = action_name
          @http_url = url
          super
        end

        def perform(*)
          HTTPInstrumentation.instrument("ethon") do |payload|
            retval = super

            payload[:http_method] = @http_method
            payload[:url] = @http_url
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
