if defined?(OpenTelemetry::SDK)
  OpenTelemetry::SDK.configure do |c|
    c.use_all
  end
end

if defined?(Datadog)
  require "ddtrace/auto_instrument"
end

if defined?(WebMock)
  WebMock.disable_net_connect!(allow_localhost: true)
end
