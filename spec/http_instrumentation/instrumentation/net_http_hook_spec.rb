# frozen_string_literal: true

require_relative "../../spec_helper"

describe HTTPInstrumentation::Instrumentation::NetHTTPHook do
  let(:url) { TEST_URL }

  it "instruments GET requests" do
    response, notifications = test_http_request { Net::HTTP.get(URI(url)) }
    expect(response).to eq("GET OK")
    expect(notifications).to eq [{http_method: :get, url: url, uri: URI(url), status_code: 200, count: 1, client: "net/http"}]
  end

  it "instruments POST requests" do
    response, notifications = test_http_request { Net::HTTP.post(URI(url), nil) }
    expect(response.body).to eq("POST OK")
    expect(notifications).to eq [{http_method: :post, url: url, uri: URI(url), status_code: 200, count: 1, client: "net/http"}]
  end
end
