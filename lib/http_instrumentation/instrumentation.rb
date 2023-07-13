# frozen_string_literal: true

require_relative "instrumentation/curb_impl"
require_relative "instrumentation/ethon_impl"
require_relative "instrumentation/excon_impl"
require_relative "instrumentation/httpclient_impl"
require_relative "instrumentation/http_impl"
require_relative "instrumentation/httpx_impl"
require_relative "instrumentation/net_http_impl"
require_relative "instrumentation/patron_impl"

module HTTPInstrumentation
  module Instrumentation
    class << self
      def instrument!(klass, instrumentation_module)
        klass.prepend(instrumentation_module) unless klass.include?(instrumentation_module)
      end

      def normalize_http_method(method)
        return nil if method.nil?
        method.to_s.downcase.to_sym
      end
    end
  end
end
