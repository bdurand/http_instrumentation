# frozen_string_literal: true

require_relative "../spec_helper"

if HTTPInstrumentation::Instrumentation::HTTPXHook.installed?
  describe HTTPInstrumentation::Instrumentation::HTTPXHook do
    let(:url) { TEST_URL }

    it "instruments GET requests" do
      response, notifications = test_http_request { HTTPX.get(url) }
      expect(response.body.to_s).to eq("GET OK")
      expect(notifications).to eq [{http_method: :get, url: url, uri: URI(url), status_code: 200, count: 1, client: "httpx"}]
    end

    it "instruments POST requests" do
      response, notifications = test_http_request { HTTPX.post(url) }
      expect(response.body.to_s).to eq("POST OK")
      expect(notifications).to eq [{http_method: :post, url: url, uri: URI(url), status_code: 200, count: 1, client: "httpx"}]
    end

    it "instruments a count for concurrent requests" do
      responses, notifications = test_http_request { HTTPX.get(url, "#{url}?t=1") }
      expect(responses.collect(&:body).collect(&:to_s)).to eq(["GET OK", "GET OK"])
      expect(notifications).to eq [{count: 2, client: "httpx"}]
    end
  end
end
