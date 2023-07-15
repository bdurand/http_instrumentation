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

begin
  Bundler.require(:default, :test)
rescue => e
  puts e.message, e.backtrace.join("\n")
  raise e
end

require "active_support"

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

  subscription = ActiveSupport::Notifications.subscribe("request.http") do |*args|
    event = ActiveSupport::Notifications::Event.new(*args)
    payloads << event.payload
  end

  yield

  ActiveSupport::Notifications.unsubscribe(subscription)

  payloads
end
