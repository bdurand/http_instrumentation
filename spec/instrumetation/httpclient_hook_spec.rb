# frozen_string_literal: true

require_relative "../spec_helper"

if defined?(HTTPClient)
  describe HTTPInstrumentation::Instrumentation::HTTPClientHook do
    let(:url) { TEST_URL }

    it "instruments GET requests" do
      response, notifications = test_http_request { HTTPClient.get(url) }
      expect(response.body).to eq("GET OK")
      expect(notifications).to eq [{http_method: :get, url: url, uri: URI(url), status_code: 200, count: 1, client: "httpclient"}]
    end

    it "instruments POST requests" do
      response, notifications = test_http_request { HTTPClient.post(url, body: "foo") }
      expect(response.body).to eq("POST OK")
      expect(notifications).to eq [{http_method: :post, url: url, uri: URI(url), status_code: 200, count: 1, client: "httpclient"}]
    end
  end
end
