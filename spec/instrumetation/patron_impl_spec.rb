# frozen_string_literal: true

require_relative "../spec_helper"

describe HTTPInstrumentation::Instrumentation::PatronImpl do
  let(:url) { TEST_URL }

  it "instruments GET requests" do
    response, notifications = test_http_request do
      session = Patron::Session.new
      response = session.get(url)
    end
    expect(response.body.to_s).to eq("GET OK")
    expect(notifications).to eq [{method: :get, url: url, status: 200, client: "patron"}]
  end

  it "instruments POST requests" do
    response, notifications = test_http_request do
      session = Patron::Session.new
      response = session.post(url, "foo")
    end
    expect(response.body.to_s).to eq("POST OK")
    expect(notifications).to eq [{method: :post, url: url, status: 200, client: "patron"}]
  end
end
