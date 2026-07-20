# frozen_string_literal: true

require "spec_helper"

RSpec.describe HTTPInstrumentation do
  describe "initialize!" do
    let(:hooks) do
      {
        curb: HTTPInstrumentation::Instrumentation::CurbHook,
        ethon: HTTPInstrumentation::Instrumentation::EthonHook,
        excon: HTTPInstrumentation::Instrumentation::ExconHook,
        http: HTTPInstrumentation::Instrumentation::HTTPHook,
        httpclient: HTTPInstrumentation::Instrumentation::HTTPClientHook,
        httpx: HTTPInstrumentation::Instrumentation::HTTPXHook,
        net_http: HTTPInstrumentation::Instrumentation::NetHTTPHook,
        patron: HTTPInstrumentation::Instrumentation::PatronHook,
        typhoeus: HTTPInstrumentation::Instrumentation::TyphoeusHook
      }
    end

    it "instruments all libraries except the ones in the except option" do
      hooks.each do |name, hook|
        if name == :curb
          expect(hook).to_not receive(:instrument!)
        else
          expect(hook).to receive(:instrument!)
        end
      end
      HTTPInstrumentation.initialize!(except: [:curb])
    end

    it "instruments only the libraries in the only option" do
      hooks.each do |name, hook|
        if name == :net_http
          expect(hook).to receive(:instrument!)
        else
          expect(hook).to_not receive(:instrument!)
        end
      end
      HTTPInstrumentation.initialize!(only: [:net_http])
    end
  end

  describe "instrument" do
    it "converts to client name to a string" do
      data = HTTPInstrumentation.instrument(:test) do |payload|
        payload
      end
      expect(data[:client]).to eq("test")
    end

    it "can override the client name" do
      retval = HTTPInstrumentation.client(:foo) do
        data = HTTPInstrumentation.instrument(:test) do |payload|
          payload
        end
        expect(data[:client]).to eq("foo")
        :value
      end
      expect(retval).to eq :value
    end

    it "can get the current client name" do
      HTTPInstrumentation.client(:foo) do
        expect(HTTPInstrumentation.client).to eq("foo")
      end
    end

    it "converts to method to a symbol" do
      data = HTTPInstrumentation.instrument(:test) do |payload|
        payload[:http_method] = "GET"
        payload
      end
      expect(data[:http_method]).to eq(:get)
    end

    it "converts the url to a string" do
      data = HTTPInstrumentation.instrument(:test) do |payload|
        payload[:url] = URI("http://example.com")
        payload
      end
      expect(data[:url]).to eq("http://example.com")
    end

    it "strips user and password credentials from the URL" do
      data = HTTPInstrumentation.instrument(:test) do |payload|
        payload[:url] = URI("http://user:passwd@example.com")
        payload
      end
      expect(data[:url]).to eq("http://example.com")
    end

    it "strips access tokens from the URL and separates the query string" do
      data = HTTPInstrumentation.instrument(:test) do |payload|
        payload[:url] = URI("http://example.com?foo=bar&access_token=secret&baz=qux")
        payload
      end
      expect(data[:url]).to eq("http://example.com")
    end

    it "strips the entire query string if the access token was the only parameter" do
      data = HTTPInstrumentation.instrument(:test) do |payload|
        payload[:url] = URI("http://example.com?access_token=secret")
        payload
      end
      expect(data[:url]).to eq("http://example.com")
    end

    it "adds a sanitized :uri to the payload" do
      data = HTTPInstrumentation.instrument(:test) do |payload|
        payload[:url] = URI("http://example.com?t=1&access_token=secret")
        payload
      end
      expect(data[:uri]).to eq(URI("http://example.com?t=1"))
    end

    it "handles relative URLs in the payload" do
      data = HTTPInstrumentation.instrument(:test) do |payload|
        payload[:url] = "/api/foo?t=1"
        payload
      end
      expect(data[:url]).to eq("/api/foo")
      expect(data[:uri]).to eq(URI("/api/foo?t=1"))
    end

    it "sets the count in the payload even if the block raises an error" do
      payloads = capture_notifications do
        expect {
          HTTPInstrumentation.instrument(:test) { raise "boom" }
        }.to raise_error("boom")
      end
      expect(payloads.size).to eq(1)
      expect(payloads.first[:client]).to eq("test")
      expect(payloads.first[:count]).to eq(1)
    end

    it "handles bad URLs in the payload" do
      data = HTTPInstrumentation.instrument(:test) do |payload|
        payload[:url] = 1.chr
        payload
      end
      expect(data[:url]).to eq(1.chr)
      expect(data).to_not include(:uri)
    end

    it "downcases the protocol and host in the uri" do
      data = HTTPInstrumentation.instrument(:test) do |payload|
        payload[:url] = URI("HTTP://EXAMPLE.COM/test")
        payload
      end
      expect(data[:uri]).to eq(URI("HTTP://EXAMPLE.COM/test"))
      expect(data[:uri].scheme).to eq("http")
      expect(data[:uri].host).to eq("example.com")
    end

    it "converts the status to an integer" do
      data = HTTPInstrumentation.instrument(:test) do |payload|
        payload[:status_code] = "200"
        payload
      end
      expect(data[:status_code]).to eq(200)
    end
  end

  describe "silence" do
    it "does not instrument the code inside a silence block" do
      payloads = capture_notifications do
        retval = HTTPInstrumentation.instrument(:test) do |payload|
          :one
        end
        expect(retval).to eq(:one)
      end
      expect(payloads).to eq([{client: "test", count: 1}])

      payloads = capture_notifications do
        expect(HTTPInstrumentation.silenced?).to be false

        retval = HTTPInstrumentation.silence do
          expect(HTTPInstrumentation.silenced?).to be true
          HTTPInstrumentation.instrument(:test) do |payload|
            :two
          end
        end

        expect(retval).to eq(:two)
        expect(HTTPInstrumentation.silenced?).to be false
      end
      expect(payloads).to eq([])

      payloads = capture_notifications do
        retval = HTTPInstrumentation.instrument(:test) do |payload|
          :three
        end
        expect(retval).to eq(:three)
      end
      expect(payloads).to eq([{client: "test", count: 1}])
    end
  end
end
