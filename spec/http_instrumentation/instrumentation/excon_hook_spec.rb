# frozen_string_literal: true

require_relative "../../spec_helper"

if HTTPInstrumentation::Instrumentation::ExconHook.installed?
  describe HTTPInstrumentation::Instrumentation::ExconHook do
    let(:url) { TEST_URL }

    it "instruments GET requests" do
      response, notifications = test_http_request { Excon.get(url) }
      expect(response.body).to eq("GET OK")
      expect(notifications).to eq [{http_method: :get, url: url, uri: URI(url), status_code: 200, count: 1, client: "excon"}]
    end

    it "instruments GET requests with query strings" do
      response, notifications = test_http_request { Excon.get("#{url}?t=1") }
      expect(response.body).to eq("GET OK")
      expect(notifications).to eq [{http_method: :get, url: url, uri: URI("#{url}?t=1"), status_code: 200, count: 1, client: "excon"}]
    end

    it "instruments POST requests" do
      response, notifications = test_http_request { Excon.post(url) }
      expect(response.body).to eq("POST OK")
      expect(notifications).to eq [{http_method: :post, url: url, uri: URI(url), status_code: 200, count: 1, client: "excon"}]
    end

    it "encodes hash query params and strips access tokens from them" do
      response, notifications = test_http_request { Excon.get(url, query: {access_token: "secret", t: 1}) }
      expect(response.body).to eq("GET OK")
      expect(notifications).to eq [{http_method: :get, url: url, uri: URI("#{url}?t=1"), status_code: 200, count: 1, client: "excon"}]
    end

    it "passes response blocks through to the client" do
      chunks = []
      response, notifications = test_http_request { Excon.get(url) { |chunk, remaining, total| chunks << chunk } }
      expect(response.status).to eq(200)
      expect(chunks.join).to eq("GET OK")
      expect(notifications).to eq [{http_method: :get, url: url, uri: URI(url), status_code: 200, count: 1, client: "excon"}]
    end

    it "reports per request values rather than connection defaults" do
      connection = Excon.new(url.sub("/test", "/other?x=1"))
      response, notifications = test_http_request { connection.request(method: :get, path: "/test", query: "t=1") }
      expect(response.body).to eq("GET OK")
      expect(notifications).to eq [{http_method: :get, url: url, uri: URI("#{url}?t=1"), status_code: 200, count: 1, client: "excon"}]
    end
  end
end
