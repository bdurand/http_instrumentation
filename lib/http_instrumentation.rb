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
    :net_http2,
    :patron,
    :typhoeus
  ].freeze

  EVENT = "request.http"

  class << self
    # Add instrumentation into HTTP client libraries. By default all supported
    # libraries are instrumented. You can pass the only or except options
    # to limit the instrumentation to a subset of libraries.
    #
    # @param only [Array<Symbol>] List of libraries to instrument.
    # @param except [Array<Symbol>] List of libraries to not instrument.
    # @return [void]
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
      Instrumentation::TyphoeusHook.instrument! if list.include?(:typhoeus)
    end

    # Silence instrumentation for the duration of the block.
    #
    # @return [Object] the return value of the block
    def silence(&block)
      save_val = Thread.current[:http_instrumentation_silence]
      begin
        Thread.current[:http_instrumentation_silence] = true
        yield
      ensure
        Thread.current[:http_instrumentation_silence] = save_val
      end
    end

    # Returns true if instrumentation is currently silenced.
    #
    # @return [Boolean]
    def silenced?
      !!Thread.current[:http_instrumentation_silence]
    end

    # Instrument the given block with the given client name. An ActiveSupport event will be
    # fired with the following payload:
    #
    # * `:client` - The name of the client as a string.
    # * `:http_method` - The HTTP method as a lowercase symbol.
    # * `:url` - The URL as a string.
    # * `:uri` - The URL as a URI object.
    # * `:status_code` - The HTTP status code as an integer.
    # * `:count` - The number of requests made as an integer.
    #
    # @param client [String, Symbol] The name of the client.
    # @return [Object] the return value of the block
    def instrument(client, &block)
      payload = {client: client.to_s}

      return yield(payload) if silenced?

      ActiveSupport::Notifications.instrument(EVENT, payload) do
        retval = silence { yield(payload) }

        payload[:http_method] = normalize_http_method(payload[:http_method]) if payload.include?(:http_method)

        if payload.include?(:url)
          uri = sanitized_uri(payload[:url])
          if uri
            payload[:url] = uri.to_s
            payload[:uri] = uri
          else
            payload[:url] = payload[:url]&.to_s
          end
        end

        payload[:status_code] = payload[:status_code]&.to_i if payload.include?(:status_code)

        payload[:count] = (payload.include?(:count) ? payload[:count].to_i : 1)

        retval
      end
    end

    private

    # Turn the given value into a lowercase symbol.
    def normalize_http_method(method)
      return nil if method.nil?
      method.to_s.downcase.to_sym
    end

    # Remove any sensitive information from the given URL. Also normalizes
    # the host and protocol by downcasing them.
    #
    # @param url [URI] the sanitized URL
    def sanitized_uri(url)
      return nil if url.nil?

      begin
        uri = URI(url.to_s)
      rescue URI::Error
        return nil
      end

      uri.password = nil
      uri.user = nil
      uri.host = uri.host&.downcase

      if uri.respond_to?(:query=) && uri.query
        params = nil
        begin
          params = URI.decode_www_form(uri.query)
        rescue
          params = {}
        end
        params.reject! { |name, value| name == "access_token" }
        uri.query = (params.empty? ? nil : URI.encode_www_form(params))
      end

      uri
    end
  end
end

HTTPInstrumentation.initialize!
