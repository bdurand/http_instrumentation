# frozen_string_literal: true

require_relative "../spec_helper"

describe HTTPInstrumentation::Instrumentation::HTTPHook do
  let(:url) { TEST_URL }

  it "instruments GET requests" do
    response, notifications = test_http_request { HTTP.get(url) }
    expect(response.body.to_s).to eq("GET OK")
    expect(notifications).to eq [{http_method: :get, url: url, uri: URI(url), status_code: 200, count: 1, client: "http"}]
  end

  it "instruments POST requests" do
    response, notifications = test_http_request { HTTP.post(url) }
    expect(response.body.to_s).to eq("POST OK")
    expect(notifications).to eq [{http_method: :post, url: url, uri: URI(url), status_code: 200, count: 1, client: "http"}]
  end
end
