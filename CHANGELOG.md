# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## 1.0.2

### Fixed
- The `except` option to `HTTPInstrumentation.initialize!` now excludes the listed libraries instead of instrumenting only those libraries.
- Requests made with relative URLs (e.g. a patron session with a `base_url`) no longer raise `URI::InvalidURIError` from the instrumentation after the request completes.
- Installing the instrumentation is now protected by a mutex so concurrent calls to `initialize!` cannot install the aliased methods twice, which would have caused infinite recursion on subsequent requests.
- The excon instrumentation now reports per-request values (path, query, etc.) instead of letting the connection's defaults override them in the event payload.
- The event payload now always includes the `:count` key even when the request raises an error.
- The net/http instrumentation no longer lets an error raised while building the event payload escape to the caller, matching the behavior of the other hooks.
- The ethon instrumentation clears the request info captured from `http_request` after each `perform`, so reusing an easy handle without going through `http_request` no longer reports the previous request's method and URL. The URL set directly on the handle is now also reported as a fallback.
- The `:url` payload value no longer includes an explicit port for URLs using the default port for their scheme.

## 1.0.1

### Fixed
- Added detection for other gems that may be instrumenting these same libraries and ensuring that the method of injecting the instrumentation call is compatible. This fixes issues caused by the fundamental incompatibility in Ruby between `alias_method` and `prepend` on the same method. Aliasing is now the default method for injection since this is the most compatible. However if another library has already prepended behavior on a method, then `prepend` will be used instead.
- `HTTPInstrumentation.client` properly returns the block return value if it was called with a block.

## 1.0.0

### Added
- Initial release.
