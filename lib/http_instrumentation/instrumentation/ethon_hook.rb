# frozen_string_literal: true

module HTTPInstrumentation
  module Instrumentation
    module EthonHook
      class << self
        def instrument!
          Instrumentation.instrument!(::Ethon::Easy, Easy) if defined?(::Ethon::Easy)
          Instrumentation.instrument!(::Ethon::Multi, Multi) if defined?(::Ethon::Multi)
        end
      end

      module Multi
        def perform(*)
          HTTPInstrumentation.instrument("ethon") do |payload|
            payload[:count] = easy_handles.size

            super
          end
        end
      end

      module Easy
        def http_request(url, action_name, *args)
          @http_method = action_name
          super
        end

        def perform(*)
          HTTPInstrumentation.instrument("ethon") do |payload|
            retval = super

            payload[:method] = @http_method
            payload[:url] = url
            payload[:status] = response_code

            retval
          end
        end
      end
    end
  end
end