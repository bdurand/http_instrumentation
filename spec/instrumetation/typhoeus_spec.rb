# frozen_string_literal: true

require_relative "../spec_helper"

describe HTTPInstrumentation::Instrumentation::TyphoeusHook do
  let(:url) { TEST_URL }

  it "instruments GET requests" do
    response, notifications = test_http_request { Typhoeus.get(url) }
    expect(response.body).to eq("GET OK")
    expect(notifications).to eq [{http_method: :get, url: url, uri: URI(url), status_code: 200, count: 1, client: "typhoeus"}]
  end

  it "instruments POST requests" do
    response, notifications = test_http_request { Typhoeus.post(url) }
    expect(response.body).to eq("POST OK")
    expect(notifications).to eq [{http_method: :post, url: url, uri: URI(url), status_code: 200, count: 1, client: "typhoeus"}]
  end

  it "instruments a count for concurrent requests" do
    responses, notifications = test_http_request do
      request_1 = Typhoeus::Request.new(url)
      request_2 = Typhoeus::Request.new("#{url}?t=1")
      hydra = Typhoeus::Hydra.hydra
      hydra.queue(request_1)
      hydra.queue(request_2)
      hydra.run
      [request_1.response, request_2.response]
    end
    expect(responses.collect(&:body).collect(&:to_s)).to eq(["GET OK", "GET OK"])
    expect(notifications).to eq [{count: 2, client: "typhoeus"}]
  end
end
