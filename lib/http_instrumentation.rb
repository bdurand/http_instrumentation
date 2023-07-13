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
  ].freeze

  EVENT = "request.http"

  class << self
    def initialize!(only: nil, except: nil)
      list = (only || IMPLEMENTATIONS)
      list &= Array(except) if except

      Instrumentation::CurbHook.instrument! if list.include?(:curb)
      Instrumentation::EthonHook.instrument! if list.include?(:ethon)
      Instrumentation::ExconHook.instrument! if list.include?(:excon)
      Instrumentation::HTTPHook.instrument! if list.include?(:http)
      Instrumentation::HTTPClientHook.instrument! if list.include?(:httpclient)
      Instrumentation::HTTPXHook.instrument! if list.include?(:httpx)
      Instrumentation::NetHTTPHook.instrument! if list.include?(:net_http)
      Instrumentation::PatronHook.instrument! if list.include?(:patron)
    end

    def silence(&block)
      save_val = Thread.current[:http_instrumentation_silence]
      begin
        Thread.current[:http_instrumentation_silence] = true
        yield
      ensure
        Thread.current[:http_instrumentation_silence] = save_val
      end
    end

    def silenced?
      !!Thread.current[:http_instrumentation_silence]
    end

    def instrument(client, &block)
      payload = {client: client.to_s}

      return yield(payload) if silenced?

      ActiveSupport::Notifications.instrument(EVENT, payload) do
        retval = yield(payload)

        payload[:method] = normalize_http_method(payload[:method]) if payload.include?(:method)
        payload[:url] = sanitize_url(payload[:url]) if payload.include?(:url)
        payload[:status] = payload[:status]&.to_i if payload.include?(:status)
        payload[:count] = payload[:count]&.to_i if payload.include?(:count)

        retval
      end
    end

    private

    def normalize_http_method(method)
      return nil if method.nil?
      method.to_s.downcase.to_sym
    end

    def sanitize_url(url)
      return nil if url.nil?

      begin
        uri = URI(url.to_s)

        uri.password = nil if uri.respond_to?(:password=)
        uri.user = nil if uri.respond_to?(:user=)

        if uri.respond_to?(:query=) && uri.query
          params = URI.decode_www_form(uri.query)
          params.reject! { |name, value| name == "access_token" }
          uri.query = (params.empty? ? nil : URI.encode_www_form(params))
        end

        uri.to_s
      rescue URI::Error
        url.to_s
      end
    end
  end
end

require_relative "http_instrumentation/railtie" if defined?(Rails::Railtie)
