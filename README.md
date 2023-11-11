# HTTP Instrumentation

[![Continuous Integration](https://github.com/bdurand/http_instrumentation/actions/workflows/continuous_integration.yml/badge.svg)](https://github.com/bdurand/http_instrumentation/actions/workflows/continuous_integration.yml)
[![Regression Test](https://github.com/bdurand/http_instrumentation/actions/workflows/regression_test.yml/badge.svg)](https://github.com/bdurand/http_instrumentation/actions/workflows/regression_test.yml)
[![Ruby Style Guide](https://img.shields.io/badge/code_style-standard-brightgreen.svg)](https://github.com/testdouble/standard)

This gem adds instrumentation to a variety of the most commonly used Ruby HTTP client libraries via ActiveSupport notifications. The goal is to add a common instrumentation interface across all the HTTP client libraries used by an application (including ones installed as dependencies of other gems).

### Supported Libraries

* [net/http](https://docs.ruby-lang.org/en/master/Net/HTTP.html) (from the Ruby standard library)
* [curb](https://github.com/taf2/curb)
* [ethon](https://github.com/typhoeus/ethon)
* [excon](https://github.com/excon/excon)
* [http](https://github.com/httprb/http) (a.k.a. http.rb)
* [httpclient](https://github.com/nahi/httpclient)
* [httpx](https://github.com/HoneyryderChuck/httpx)
* [patron](https://github.com/toland/patron)
* [typhoeus](https://github.com/typhoeus/typhoeus)

Note that several other popular HTTP client libraries like [Faraday](https://github.com/lostisland/faraday), [HTTParty](https://github.com/jnunemaker/httparty), and [RestClient](https://github.com/rest-client/rest-client) are built on top of these low level libraries.

## Usage

To capture information about HTTP requests, simply subscribe to the `request.http` events with [ActiveSupport notifications](https://api.rubyonrails.org/classes/ActiveSupport/Notifications.html) (note that you should really use `monotonic_subscribe` instead of `subscribe` to avoid issues with clock adjustments).

The payload on event notifications for all HTTP requests will include:

* `:client` - The client library used to make the request
* `:count` - The number of HTTP requests that were made

If a single HTTP request was made, then these keys will exist as well:

* `:uri` - The URI for the request
* `:url` - The URL for the request with any query string stripped off
* `:http_method` - The HTTP method for the request
* `:status_code` - The numeric HTTP status code for the response

These additional values will not be present if multiple, concurrent requests were made. Only the typhoeus, ethon, and httpx libraries support making concurrent requests.

```ruby
ActiveSupport::Notifications.monotonic_subscribe("request.http") do |*args|
  event = ActiveSupport::Notifications::Event.new(*args)
  client = event.payload[:client]
  count = event.payload[:count]
  url = event.payload[:url]
  uri = event.payload[:uri]
  http_method = event.payload[:http_method]
  status_code = event.payload[:status_code]

  puts "HTTP request: client: #{client}, count: #{count}, duration: #{event.duration}ms"
  if count == 1
    puts "#{http_method} #{url} - status: #{status_code}, host: #{uri&.host}"
  end
end

# Single request
Net::HTTP.get(URI("https://example.com/info"))
# => HTTP request: client: net/http, count: 1, duration: 100ms
# => GET https://example.com/info - status 200, host: example.com

# Multiple, concurrent requests
HTTPX.get("https://example.com/r1", "https://example.com/r2")
# => HTTP request: client: httpx, count: 2, duration: 150ms
```

### Security

The `:uri` element in the event payload will be sanitized to remove any user/password elements encoded in the URL as well as any `access_token` query parameters.

The `:url` element will also have the query string stripped from it so it will just include the scheme, host, and path.

```ruby
HTTP.get("https://user@password123@example.com/path")
HTTP.get("https://example.com/path?access_token=secrettoken")
# event.payload[:url] will be https://example.com/path in both cases
```

The hostname will also be converted to lowercase in these attributes.

### Silencing Notifications

If you want to suppress notifications, you can do so by surrounding code with an `HTTPInstrumentation.silence` block.

```ruby
HTTPInstrumentation.silence do
  HTTP.get("https://example.com/info") # Notification will not be sent
end
```

### Custom HTTP Clients

You can instrument additional HTTP calls with the `HTTPInstrumentation.instrument` method. Adding instrumentation to higher level clients will suppress any instrumentation from lower level clients they may be using so you'll only get one event per request.

```ruby
class MyHttpClient
  def get(url)
    HTTPInstrumentation.instrument("my_client") do |payload|
      response = Net::HTTP.get(URI(url))

      payload[:http_method] = :get
      payload[:url] = url
      payload[:status_code] = response.code

      response
    end
  end
end

MyHttpClient.get("https://example.com/")
# Event => {client: "my_client", http_method => :get, url: "https://example.com/"}
```

You can also take advantage of the existing instrumentation and just override the client name in the notification event.

```ruby
class MyHttpClient
  def get(url)
    HTTPInstrumentation.client("my_client")
      Net::HTTP.get(URI(url))
    end
  end
end

MyHttpClient.get("https://example.com/")
# Event => {client: "my_client", http_method => :get, url: "https://example.com/"}
```

## Installation

Add this line to your application's Gemfile:

```ruby
gem "http_instrumentation"
```

Then execute:
```bash
$ bundle
```

Or install it yourself as:
```bash
$ gem install http_instrumentation
```

## Contributing

Open a pull request on [GitHub](https://github.com/bdurand/http_instrumentation).

Please use the [standardrb](https://github.com/testdouble/standard) syntax and lint your code with `standardrb --fix` before submitting.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).