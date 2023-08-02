# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## 1.0.1

### Fixed
- Added detection for other gems that may be instrumenting these same libraries and ensuring that the method of injecting the instrumentation call is compatible. This fixes issues caused by the fundamental incompatibility in Ruby between `alias_method` and `prepend` on the same method. Aliasing is now the default method for injection since this is the most compatible. However if another library has already prepended behavior on a method, then `prepend` will be used instead.

## 1.0.0

### Added
- Initial release.
