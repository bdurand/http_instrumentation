# frozen_string_literal: true

require "spec_helper"

if HTTPInstrumentation::Instrumentation::PatronHook.installed?
  RSpec.describe HTTPInstrumentation::Instrumentation::PatronHook do
    let(:url) { TEST_URL }

    it "instruments GET requests" do
      response, notifications = test_http_request do
        session = Patron::Session.new
        response = session.get(url)
      end
      expect(response.body.to_s).to eq("GET OK")
      expect(notifications).to eq [{http_method: :get, url: url, uri: URI(url), status_code: 200, count: 1, client: "patron"}]
    end

    it "instruments POST requests" do
      response, notifications = test_http_request do
        session = Patron::Session.new
        response = session.post(url, "foo")
      end
      expect(response.body.to_s).to eq("POST OK")
      expect(notifications).to eq [{http_method: :post, url: url, uri: URI(url), status_code: 200, count: 1, client: "patron"}]
    end

    it "instruments requests made with a relative URL on a session with a base_url" do
      uri = URI(url)
      response, notifications = test_http_request do
        session = Patron::Session.new
        session.base_url = "#{uri.scheme}://#{uri.host}:#{uri.port}"
        response = session.get(uri.path)
      end
      expect(response.body.to_s).to eq("GET OK")
      expect(notifications).to eq [{http_method: :get, url: uri.path, uri: URI(uri.path), status_code: 200, count: 1, client: "patron"}]
    end
  end
end
