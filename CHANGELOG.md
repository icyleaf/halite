# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/en/1.0.0/)
and this project adheres to [Semantic Versioning](http://semver.org/spec/v2.0.0.html).

## [Unreleased]

> TODO

### Changed

- Change instance `Halite::Client` with block behavior. [#33](https://github.com/icyleaf/halite/issues/33)
- Renamed argument name `adapter` to `format` in `#logger` chainable method.
- Move logger into features.

### Added

- Add features support (aka middleware), you can create monitor or interceptor. [#29](https://github.com/icyleaf/halite/issues/29)
- Add `#logging` in chainable method.

### Fixed

- Add misisng `#request` method with headers, params, form, json, raw, ssl arguments.
- Fix do not overwrite default headers with exists one by using `Halite::Options.merge`.
- Typo and correct words in README. (thanks @[megatux](https://github.com/megatux))

## [0.6.0] (2018-08-24)

> Improve performance with :love:

### Changed

- Set `logger` to nil when instance a `Halite::Options`, it throws a `Halite::Error` exception if enable `logging`.
- Change `Halite::Options` accepts argument inside. no ffect for users. [#27](https://github.com/icyleaf/halite/pull/27)
- Wrap all exception class into a module, better for reading document.

### Fixed

- Fix always return `#` with `#full_path` if fragment not exists in `Halite::Request`.
- Fix always overwrite with default headers with `#merge` in `Halite::Options`

### Tested

- Compatibility with Crystal 0.26

## [0.5.0] (2018-07-03)

### Changed

- New logger system and json logger support, see [#19](https://github.com/icyleaf/halite/pull/19).
- Change verb request behavior:
  - `get`, `head` only accepts `#params` argument.
  - `post`, `put`, `delete`, `patch`, `options` accepts `#params`, `#form`, `#json` and `#raw` arguments.

### Added

- Add request [#raw](https://github.com/icyleaf/halite/#raw-string) string support. [#20](https://github.com/icyleaf/halite/issues/20) (thanks @[wirrareka](https://github.com/wirrareka))

## [0.4.0] (2018-06-27)

### Changed

- Remove `#mime_type` duplicate with `#content_type` in `Halite::Response`.
- Change write log file use append mode by default, it could be change by param.
- Change logger formatter to easy identify category(request/response).

### Added

- Add [#links](https://github.com/icyleaf/halite/#link-headers) to `Halite::Response` to fetch link headers.
- Add [#raise_for_status](https://github.com/icyleaf/halite/#raise-for-status-code) to `Halite::Response`.
- Support multiple files upload. [#14](https://github.com/icyleaf/halite/issues/14) (thanks @[BenDietze](https://github.com/BenDietze))
- Add `#to_raw` to `Halite::Response` to dump a raw of response. [#15](https://github.com/icyleaf/halite/issues/15) (thanks @[BenDietze](https://github.com/BenDietze))
- Support `OPTIONS` method (crystal 0.25.0+)
- Append write log to a file section to README.

### Fixed

- Stripped the filename in a `multipart/form-data` body. [#16](https://github.com/icyleaf/halite/issues/16) (thanks @[BenDietze](https://github.com/BenDietze))
- Fix `#domain` in `Halite::Request` with subdomian. [#17](https://github.com/icyleaf/halite/pull/17) (thanks @[007lva](https://github.com/007lva))
- Create missing directories when use path to write log to a file.

## [0.3.2] (2018-06-19)

### Fixed

Compatibility with Crystal 0.25

## [0.3.1] (2017-12-13)

### Added

- Set `Options.default_headers` to be public method.
- Accept tuples options in `Options.new`.
- Accept `follow`/`follow_strict` in `Options.new`.
- Accept options block in `Options.new`.
- Add logger during request and response (see [usage](README.md#logging)).
- Alias method `Options.read_timeout` to `Options::Timeout.read`.
- Alias method `Options.read_timeout=` to `Options::Timeout.read=`.
- Alias method `Options.connect_timeout` to `Options::Timeout.connect`.
- Alias method `Options.connect_timeout` to `Options::Timeout.connect=`.
- Alias method `Options.follow=` to `Options::Timeout.follow.hops=`.
- Alias method `Options.follow_strict` to `Options::Timeout.follow.strict`.
- Alias method `Options.follow_strict=` to `Options::Timeout.follow.strict=`.

### Fixed

- Fix store **Set-Cookies** in response and set **Cookies** in request in better way.
- Fix cant not set connect/read timeout in `Options.new`.
- Fix cant not overwrite default headers in `Options.new`.
- Fix `Options.clear!` was not clear everything and restore default headers.

## [0.2.0] (2017-11-28)

### Changed

- `HTTP::Headers#to_h` return string with each key if it contains one in array. ([commit#e057c47c](https://github.com/icyleaf/halite/commit/e057c47c4b587b27b2bae6871a1968299ce348f5))

### Added

- Add `Response#mime_type` method.
- Add `Response#history` method to support full history of redirections. ([#8](https://github.com/icyleaf/halite/issues/8))
- Add `Response#parse` method that it better body parser of response with json and write custom adapter for MIME type. ([#9](https://github.com/icyleaf/halite/issues/9))

### Fixed

- Fix issue to first char of redirect uri is not slash(/). ([#11](https://github.com/icyleaf/halite/issues/11))
- Fix raise unsafe verbs in strict mode.

## [0.1.5] (2017-10-11)

### Changed

- Only store cookies in Sessions shards. ([#7](https://github.com/icyleaf/halite/issues/7))

### Added

- Add `TLS/SSL` support (based on [HTTP::Client.new(uri : URI, tls = nil)](https://crystal-lang.org/api/0.23.1/HTTP/Client.html#new%28uri%3AURI%2Ctls%3Dnil%29-class-method)).
- Add `UnsupportedMethodError/UnsupportedSchemeError` exceptions.

### Fixed

- Timeout with redirection. ([#7](https://github.com/icyleaf/halite/issues/7))
- Compatibility with Crystal 0.24.0 (unreleased)

## [0.1.3] (2017-10-09)

### Changed

- Always instance a new Options with each request in chainable methods.

### Added

- Add `accept` method.

### Fixed

- Fix `follow`(redirect uri) with full uri and relative path.
- Fix always overwrite request headers with default values.
- Fix always shard same options in any new call. (it only valid in chainable methods)

## 0.1.2 (2017-09-18)

- First beta version.

[Unreleased]: https://github.com/icyleaf/halite/compare/v0.6.0...HEAD
[0.6.0]: https://github.com/icyleaf/halite/compare/v0.5.0...v0.6.0
[0.5.0]: https://github.com/icyleaf/halite/compare/v0.4.0...v0.5.0
[0.4.0]: https://github.com/icyleaf/halite/compare/v0.3.2...v0.4.0
[0.3.2]: https://github.com/icyleaf/halite/compare/v0.3.1...v0.3.2
[0.3.1]: https://github.com/icyleaf/halite/compare/v0.2.0...v0.3.1
[0.2.0]: https://github.com/icyleaf/halite/compare/v0.1.5...v0.2.0
[0.1.5]: https://github.com/icyleaf/halite/compare/v0.1.3...v0.1.5
[0.1.3]: https://github.com/icyleaf/halite/compare/v0.1.2...v0.1.3
