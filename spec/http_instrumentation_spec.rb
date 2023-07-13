# frozen_string_literal: true

require_relative "spec_helper"

describe HTTPInstrumentation do
  describe "instrument" do
    it "converts to client name to a string" do
      data = HTTPInstrumentation.instrument(:test) do |payload|
        payload
      end
      expect(data[:client]).to eq("test")
    end

    it "converts to method to a symbol" do
      data = HTTPInstrumentation.instrument(:test) do |payload|
        payload[:method] = "GET"
        payload
      end
      expect(data[:method]).to eq(:get)
    end

    it "converts the url to a string" do
      data = HTTPInstrumentation.instrument(:test) do |payload|
        payload[:url] = URI("http://example.com")
        payload
      end
      expect(data[:url]).to eq("http://example.com")
    end

    it "strips user and password credentials from the URL" do
      data = HTTPInstrumentation.instrument(:test) do |payload|
        payload[:url] = URI("http://user:passwd@example.com")
        payload
      end
      expect(data[:url]).to eq("http://example.com")
    end

    it "strips access tokens from the URL" do
      data = HTTPInstrumentation.instrument(:test) do |payload|
        payload[:url] = URI("http://example.com?foo=bar&access_token=secret&baz=qux")
        payload
      end
      expect(data[:url]).to eq("http://example.com?foo=bar&baz=qux")
    end

    it "strips the entire query string if the access token was the only parameter" do
      data = HTTPInstrumentation.instrument(:test) do |payload|
        payload[:url] = URI("http://example.com?access_token=secret")
        payload
      end
      expect(data[:url]).to eq("http://example.com")
    end

    it "converts the status to an integer" do
      data = HTTPInstrumentation.instrument(:test) do |payload|
        payload[:status] = "200"
        payload
      end
      expect(data[:status]).to eq(200)
    end
  end

  describe "silence" do
    it "does not instrument the code inside a silence block" do
      payloads = capture_notifications do
        retval = HTTPInstrumentation.instrument(:test) do |payload|
          :one
        end
        expect(retval).to eq(:one)
      end
      expect(payloads).to eq([{client: "test"}])

      payloads = capture_notifications do
        expect(HTTPInstrumentation.silenced?).to be false

        retval = HTTPInstrumentation.silence do
          expect(HTTPInstrumentation.silenced?).to be true
          HTTPInstrumentation.instrument(:test) do |payload|
            :two
          end
        end

        expect(retval).to eq(:two)
        expect(HTTPInstrumentation.silenced?).to be false
      end
      expect(payloads).to eq([])

      payloads = capture_notifications do
        retval = HTTPInstrumentation.instrument(:test) do |payload|
          :three
        end
        expect(retval).to eq(:three)
      end
      expect(payloads).to eq([{client: "test"}])
    end
  end
end
