# frozen_string_literal: true

require_relative "instrumentation/curb_hook"
require_relative "instrumentation/ethon_hook"
require_relative "instrumentation/excon_hook"
require_relative "instrumentation/httpclient_hook"
require_relative "instrumentation/http_hook"
require_relative "instrumentation/httpx_hook"
require_relative "instrumentation/net_http_hook"
require_relative "instrumentation/patron_hook"
require_relative "instrumentation/typhoeus_hook"

module HTTPInstrumentation
  module Instrumentation
    class << self
      # Helper method to prepend an instrumentation module to a class.
      def instrument!(klass, instrumentation_module)
        klass.prepend(instrumentation_module) unless klass.include?(instrumentation_module)
      end
    end
  end
end
