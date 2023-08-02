# frozen_string_literal: true

require_relative "../../spec_helper"

if HTTPInstrumentation::Instrumentation::CurbHook.installed?
  describe HTTPInstrumentation::Instrumentation::CurbHook do
    let(:url) { TEST_URL }

    it "instruments GET requests" do
      response, notifications = test_http_request { Curl.get(url) }
      expect(response.body_str).to eq("GET OK")
      expect(notifications).to eq [{http_method: :get, url: url, uri: URI(url), status_code: 200, count: 1, client: "curb"}]
    end

    it "instruments POST requests" do
      response, notifications = test_http_request { Curl.post(url) }
      expect(response.body_str).to eq("POST OK")
      expect(notifications).to eq [{http_method: :post, url: url, uri: URI(url), status_code: 200, count: 1, client: "curb"}]
    end
  end
end
