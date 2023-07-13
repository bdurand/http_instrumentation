# frozen_string_literal: true

module HTTPInstrumentation
  module Instrumentation
    module EthonImpl
      class << self
        def instrument!
          Instrumentation.instrument!(::Ethon::Easy, Easy) if defined?(::Ethon::Easy)
          Instrumentation.instrument!(::Ethon::Multi, Multi) if defined?(::Ethon::Multi)
        end
      end

      module Multi
        def perform(*)
          retval = nil

          payload = {count: easy_handles.size, client: "ethon"}

          ActiveSupport::Notifications.instrument("request.http", payload) do
            retval = super
          end

          retval
        end
      end

      module Easy
        def http_request(url, action_name, *args)
          @http_method = action_name
          super
        end

        def perform(*)
          retval = nil

          payload = {method: Instrumentation.normalize_http_method(@http_method), url: url.to_s, client: "ethon"}

          ActiveSupport::Notifications.instrument("request.http", payload) do
            retval = super
            payload[:status] = response_code
          end

          retval
        end
      end
    end
  end
end
