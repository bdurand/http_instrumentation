# frozen_string_literal: true

require_relative "../spec_helper"

describe HTTPInstrumentation::Instrumentation::EthonImpl do
  let(:url) { TEST_URL }

  it "instruments GET requests" do
    response, notifications = test_http_request do
      easy = Ethon::Easy.new
      easy.http_request(url, :get)
      easy.perform
      easy
    end
    expect(response.response_body).to eq("GET OK")
    expect(notifications).to eq [{method: :get, url: url, status: 200, client: "ethon"}]
  end

  it "instruments POST requests" do
    response, notifications = test_http_request do
      easy = Ethon::Easy.new
      easy.http_request(url, :post)
      easy.perform
      easy
    end
    expect(response.response_body).to eq("POST OK")
    expect(notifications).to eq [{method: :post, url: url, status: 200, client: "ethon"}]
  end

  it "instruments a count for concurrent requests" do
    responses, notifications = test_http_request do
      multi = Ethon::Multi.new
      easy_1 = Ethon::Easy.new
      easy_1.http_request(url, :get)
      multi.add(easy_1)
      easy_2 = Ethon::Easy.new
      easy_2.http_request(url, :get)
      multi.add(easy_2)
      multi.perform
      [easy_1, easy_2]
    end
    expect(responses.collect(&:response_body)).to eq(["GET OK", "GET OK"])
    expect(notifications).to eq [{count: 2, client: "ethon"}]
  end
end
