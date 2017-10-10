# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/en/1.0.0/)
and this project adheres to [Semantic Versioning](http://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Todo

- 100% pass specs

### Add

- History of redirections
- Stream support
- Better body of response with plain text, binary, json, xml or raw data. (reference [Response Content in requests](http://docs.python-requests.org/en/master/user/quickstart/#response-content))

###

## [0.1.4] (10/10/2017)

### Added

- Add `TLS/SSL` support (based on [HTTP::Client.new(uri : URI, tls = nil)](https://crystal-lang.org/api/0.23.1/HTTP/Client.html#new%28uri%3AURI%2Ctls%3Dnil%29-class-method))
- Add `UnsupportedMethodError/UnsupportedSchemeError` exceptions

### Fixed

- Compatibility with Crystal 0.24.0 (unreleased)

## [0.1.3] (10/09/2017)

### Added

- Add `accept` method

### Changed

- Always instance a new Options with each request in chainable methods.

### Fixed

- Fix `follow`(redirect uri) with full uri and relative path
- Fix always overwrite request headers with default values
- Fix always shard same options in any new call (it only valid in chainable methods)

## 0.1.2 (09/18/2017)

- First beta version

[Unreleased]: https://github.com/icyleaf/halite/compare/v0.1.4...HEAD
[0.1.4]: https://github.com/icyleaf/halite/compare/v0.1.3...v0.1.4
[0.1.3]: https://github.com/icyleaf/halite/compare/v0.1.2...v0.1.3
