# HTTP Instrumentation :construction:

[![Continuous Integration](https://github.com/bdurand/http_instrumentation/actions/workflows/continuous_integration.yml/badge.svg)](https://github.com/bdurand/http_instrumentation/actions/workflows/continuous_integration.yml)
[![Ruby Style Guide](https://img.shields.io/badge/code_style-standard-brightgreen.svg)](https://github.com/testdouble/standard)

This gem adds instrumentation to a variety of the most popular Ruby HTTP client libraries via ActiveSupport notifications.

### Supported Libraries

* curb
* ethon
* excon
* http
* httpclient
* httpx
* net/http
* patron

## Usage

TODO

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