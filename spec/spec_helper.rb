# frozen_string_literal: true

ENV["BUNDLE_GEMFILE"] ||= File.expand_path("../Gemfile", __dir__)

require "bundler/setup" if File.exist?(ENV["BUNDLE_GEMFILE"])

require "logger"

begin
  require "simplecov"
  SimpleCov.start do
    add_filter ["/spec/", "/app/", "/config/", "/db/"]
  end
rescue LoadError
end

Bundler.require(:default, :test)

require "active_support"

require_relative "other_gems_setup"

RSpec.configure do |config|
  config.warnings = true
  config.disable_monkey_patching!
  config.default_formatter = "doc" if config.files_to_run.one?
  config.order = :random
  Kernel.srand config.seed

  server = nil

  config.before(:suite) do
    require "webrick"

    server = WEBrick::HTTPServer.new(Port: 8971, Logger: WEBrick::Log.new(File::NULL), AccessLog: [])

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

# Run a block with Ruby warnings turned off. Used when a spec has to exercise
# an API the client gem has deprecated so the deprecation notice does not
# clutter the test output.
def silence_warnings
  verbose, $VERBOSE = $VERBOSE, nil
  yield
ensure
  $VERBOSE = verbose
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
