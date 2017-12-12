# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/en/1.0.0/)
and this project adheres to [Semantic Versioning](http://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Todo

- 100% pass specs

### Added

- Accept tuples options in `Options.new`.
- Accept `follow`/`follow_strict` in `Options.new`.
- Set `Options.default_headers` to be public method.

### Fixed

- Fix cant not set connect/read timeout in `Options.new`.
- Fix cant not overwrite default in `Options.new`.
- Fix `Options.clear!` was not clear everything and restore default headers.

## [0.2.0] (11/28/2017)

### Changed

- `HTTP::Headers#to_h` return string with each key if it contains one in array. ([commit#e057c47c](https://github.com/icyleaf/halite/commit/e057c47c4b587b27b2bae6871a1968299ce348f5))

### Added

- Add `Response#mime_type` method.
- Add `Response#history` method to support full history of redirections. ([#8](https://github.com/icyleaf/halite/issues/8))
- Add `Response#parse` method that it better body parser of response with json and write custom adapter for MIME type. ([#9](https://github.com/icyleaf/halite/issues/9))

### Fixed

- Fix issue to first char of redirect uri is not slash(/). ([#11](https://github.com/icyleaf/halite/issues/11))
- Fix raise unsafe verbs in strict mode.

## [0.1.5] (10/11/2017)

### Added

- Add `TLS/SSL` support (based on [HTTP::Client.new(uri : URI, tls = nil)](https://crystal-lang.org/api/0.23.1/HTTP/Client.html#new%28uri%3AURI%2Ctls%3Dnil%29-class-method)).
- Add `UnsupportedMethodError/UnsupportedSchemeError` exceptions.

### Changed

- Only store cookies in Sessions shards. ([#7](https://github.com/icyleaf/halite/issues/7))

### Fixed

- Timeout with redirection. ([#7](https://github.com/icyleaf/halite/issues/7))
- Compatibility with Crystal 0.24.0 (unreleased)

## [0.1.3] (10/09/2017)

### Added

- Add `accept` method.

### Changed

- Always instance a new Options with each request in chainable methods.

### Fixed

- Fix `follow`(redirect uri) with full uri and relative path.
- Fix always overwrite request headers with default values.
- Fix always shard same options in any new call. (it only valid in chainable methods)

## 0.1.2 (09/18/2017)

- First beta version.

[Unreleased]: https://github.com/icyleaf/halite/compare/v0.2.0...HEAD
[0.2.0]: https://github.com/icyleaf/halite/compare/v0.1.5...v0.2.0
[0.1.5]: https://github.com/icyleaf/halite/compare/v0.1.3...v0.1.5
[0.1.3]: https://github.com/icyleaf/halite/compare/v0.1.2...v0.1.3
