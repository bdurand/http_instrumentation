# frozen_string_literal: true

require_relative "../spec_helper"

describe HTTPInstrumentation::Instrumentation::NetHTTPImpl do
  let(:url) { TEST_URL }

  it "instruments GET requests" do
    response, notifications = test_http_request { Net::HTTP.get(URI(url)) }
    expect(response).to eq("GET OK")
    expect(notifications).to eq [{method: :get, url: url, status: 200, client: "net/http"}]
  end

  it "instruments POST requests" do
    response, notifications = test_http_request { Net::HTTP.post(URI(url), nil) }
    expect(response.body).to eq("POST OK")
    expect(notifications).to eq [{method: :post, url: url, status: 200, client: "net/http"}]
  end
end
