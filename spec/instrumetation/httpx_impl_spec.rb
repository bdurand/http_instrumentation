# frozen_string_literal: true

require_relative "../spec_helper"

describe HTTPInstrumentation::Instrumentation::HTTPXImpl do
  let(:url) { TEST_URL }

  it "instruments GET requests" do
    response, notifications = test_http_request { HTTPX.get(url) }
    expect(response.body.to_s).to eq("GET OK")
    expect(notifications).to eq [{method: :get, url: url, status: 200, client: "httpx"}]
  end

  it "instruments POST requests" do
    response, notifications = test_http_request { HTTPX.post(url) }
    expect(response.body.to_s).to eq("POST OK")
    expect(notifications).to eq [{method: :post, url: url, status: 200, client: "httpx"}]
  end

  it "instruments a count for concurrent requests" do
    responses, notifications = test_http_request { HTTPX.get(url, "#{url}?t=1") }
    expect(responses.collect(&:body).collect(&:to_s)).to eq(["GET OK", "GET OK"])
    expect(notifications).to eq [{count: 2, client: "httpx"}]
  end
end
