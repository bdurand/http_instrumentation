# frozen_string_literal: true

require_relative "../spec_helper"

describe HTTPInstrumentation::Instrumentation::ExconImpl do
  let(:url) { TEST_URL }

  it "instruments GET requests" do
    response, notifications = test_http_request { Excon.get(url) }
    expect(response.body).to eq("GET OK")
    expect(notifications).to eq [{method: :get, url: url, status: 200, client: "excon"}]
  end

  it "instruments POST requests" do
    response, notifications = test_http_request { Excon.post(url) }
    expect(response.body).to eq("POST OK")
    expect(notifications).to eq [{method: :post, url: url, status: 200, client: "excon"}]
  end
end
