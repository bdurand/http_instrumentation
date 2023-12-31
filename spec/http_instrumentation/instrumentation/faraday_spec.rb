# frozen_string_literal: true

require_relative "../../spec_helper"

if defined?(Faraday)
  describe "Faraday" do
    let(:url) { TEST_URL }

    it "instruments requests via net/http" do
      response, notifications = test_http_request { Faraday.get(url) }
      expect(response.body).to eq("GET OK")
      expect(notifications).to eq [{http_method: :get, url: url, uri: URI(url), status_code: 200, count: 1, client: "net/http"}]
    end
  end
end
