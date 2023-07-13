# frozen_string_literal: true

require_relative "../spec_helper"

describe HTTPInstrumentation::Instrumentation::HTTPImpl do
  let(:url) { TEST_URL }

  it "instruments GET requests" do
    response, notifications = test_http_request { HTTP.get(url) }
    expect(response.body.to_s).to eq("GET OK")
    expect(notifications).to eq [{method: :get, url: url, status: 200, client: "http"}]
  end

  it "instruments POST requests" do
    response, notifications = test_http_request { HTTP.post(url) }
    expect(response.body.to_s).to eq("POST OK")
    expect(notifications).to eq [{method: :post, url: url, status: 200, client: "http"}]
  end
end
