# frozen_string_literal: true

begin
  require "excon"
rescue LoadError
end

module HTTPInstrumentation
  module Instrumentation
    # This module is used to instrument the excon gem.
    module ExconHook
      class << self
        def instrument!
          Instrumentation.instrument!(::Excon::Connection, self, :request) if defined?(::Excon::Connection)
        end

        def installed?
          !!(defined?(::Excon::Connection) && ::Excon::Connection.include?(self))
        end

        attr_accessor :aliased
      end

      def request(params = {})
        HTTPInstrumentation.instrument("excon") do |payload|
          response = if HTTPInstrumentation::Instrumentation::ExconHook.aliased
            request_without_http_instrumentation(params)
          else
            super
          end

          begin
            info = params
            # Merge connection defaults under the per-request params so the
            # request values win.
            if respond_to?(:connection)
              info = connection.merge(params)
            elsif respond_to?(:data)
              info = data.merge(params)
            end

            scheme = info[:scheme]&.downcase
            default_port = ((scheme == "https") ? 443 : 80)
            port = info[:port]
            payload[:http_method] = (info[:http_method] || info[:method])
            payload[:url] = "#{scheme}://#{info[:host]}#{":#{port}" unless port == default_port}#{info[:path]}#{"?#{info[:query]}" unless info[:query].to_s.empty?}"
            payload[:status_code] = response.status
          rescue
          end

          response
        end
      end
    end
  end
end
