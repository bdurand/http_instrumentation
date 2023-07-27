# frozen_string_literal: true

require_relative "../spec_helper"

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
  end
end
