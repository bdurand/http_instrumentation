# frozen_string_literal: true

require_relative "../spec_helper"

describe HTTPInstrumentation::Instrumentation::CurbImpl do
  let(:url) { TEST_URL }

  it "instruments GET requests" do
    response, notifications = test_http_request { Curl.get(url) }
    expect(response.body_str).to eq("GET OK")
    expect(notifications).to eq [{method: :get, url: url, status: 200, client: "curb"}]
  end

  it "instruments POST requests" do
    response, notifications = test_http_request { Curl.post(url) }
    expect(response.body_str).to eq("POST OK")
    expect(notifications).to eq [{method: :post, url: url, status: 200, client: "curb"}]
  end
end
