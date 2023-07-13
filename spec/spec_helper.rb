# frozen_string_literal: true

ENV["BUNDLE_GEMFILE"] ||= File.expand_path("../Gemfile", __dir__)

require "bundler/setup" if File.exist?(ENV["BUNDLE_GEMFILE"])

begin
  require "simplecov"
  SimpleCov.start do
    add_filter ["/spec/", "/app/", "/config/", "/db/"]
  end
rescue LoadError
end

Bundler.require(:default, :test)

require "active_support"

require "curb"
require "ethon"
require "excon"
require "http"
require "httpclient"
require "httpx"
require "net/http"
require "patron"

HTTPInstrumentation.initialize! unless defined?(Rails)

RSpec.configure do |config|
  config.order = :random

  server = nil

  config.before(:suite) do
    require "webrick"

    server = WEBrick::HTTPServer.new(Port: 8971, Logger: WEBrick::Log.new("/dev/null"), AccessLog: [])

    server.mount_proc "/test" do |request, response|
      response.body = "#{request.request_method} OK"
    end

    Thread.new { server.start }
  end

  config.after(:suite) do
    server.shutdown
  end
end

TEST_URL = "http://localhost:8971/test"

def test_http_request
  response = nil
  payloads = capture_notifications do
    response = yield
  end
  [response, payloads]
end

def capture_notifications
  payloads = []

  subscription = ActiveSupport::Notifications.subscribe("request.http") do |name, start, finish, id, payload|
    payloads << payload
  end

  yield

  ActiveSupport::Notifications.unsubscribe(subscription)

  payloads
end
