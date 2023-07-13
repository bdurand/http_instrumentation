# frozen_string_literal: true

require "active_support/notifications"

require_relative "http_instrumentation/instrumentation"

module HTTPInstrumentation
  IMPLEMENTATIONS = [
    :curb,
    :ethon,
    :excon,
    :http,
    :httpclient,
    :httpx,
    :net_http,
    :patron
  ]

  class << self
    def instrument!(only: nil, except: nil)
      list = (only || IMPLEMENTATIONS)
      list &= Array(except) if except

      Instrumentation::CurbImpl.instrument! if list.include?(:curb)
      Instrumentation::EthonImpl.instrument! if list.include?(:ethon)
      Instrumentation::ExconImpl.instrument! if list.include?(:excon)
      Instrumentation::HTTPImpl.instrument! if list.include?(:http)
      Instrumentation::HTTPClientImpl.instrument! if list.include?(:httpclient)
      Instrumentation::HTTPXImpl.instrument! if list.include?(:httpx)
      Instrumentation::NetHTTPImpl.instrument! if list.include?(:net_http)
      Instrumentation::PatronImpl.instrument! if list.include?(:patron)
    end
  end
end
