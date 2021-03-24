# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/en/1.0.0/)
and this project adheres to [Semantic Versioning](http://semver.org/spec/v2.0.0.html).

## [Unreleased]

> List all changes before release a new version.

### Todo

- [ ] Rewrite HTTP Connection
  - [ ] New Connection for Halite
  - [x] Proxy support
  - [ ] Reuse connection

## [0.12.0] (2021-03-24)

- Compatibility with Crystal 1.0.

## [0.11.0] (2021-02-18)

> Finally, the major version was out! Happy new year!

### Changed

- **[breaking changing]** Drop file logging in favor of Crystal's [Log](https://crystal-lang.org/api/0.36.1/Log.html). (removed `.logging(file: )`, use `.logging(for: )` instead)  [#101](https://github.com/icyleaf/halite/pull/101) (thanks @[oprypin](https://github.com/oprypin))
- Pre-read `TZ` environment value to convert timestamp's timezone during logging output. [#102](https://github.com/icyleaf/halite/pull/102)
- Crystal 0.34.x support.

## [0.10.9] (2021-02-01)

### Fixed

- `timeout` fail to match argument type. [#97](https://github.com/icyleaf/halite/issues/97) (thanks @[oprypin](https://github.com/oprypin))
- Compatibility with Crystal 0.36.0.

## [0.10.8] (2020-12-22)

### Fixed

- Resolve path of endpoint ending without slash. [#94](https://github.com/icyleaf/halite/issues/94) (thanks @[mipmip](https://github.com/mipmip))

## [0.10.7] (2020-12-08)
### Fixed

- Fix initial status_message. [#91](https://github.com/icyleaf/halite/issues/91) (thanks @[oprypin](https://github.com/oprypin))

## [0.10.6] (2020-11-24)
### Fixed

- Improve resolve of URI. [#88](https://github.com/icyleaf/halite/issues/88) (thanks @[oprypin](https://github.com/oprypin))

## [0.10.5] (2020-04-15)

### Fixed

- Compatibility with Crystal 0.34.0.

## [0.10.4] (2019-09-26)

### Fixed

- Compatibility with Crystal 0.31.0.

## [0.10.3] (2019-08-12)

### Fixed

- Compatibility with Crystal 0.30.0.

## [0.10.2] (2019-06-24)

### Fixed

- Fixed Basic Auth creates bad headers in crystal 0.29.0. [#73](https://github.com/icyleaf/halite/pull/73) (thanks @[kalinon](https://github.com/kalinon))
- Fixed use one shared options in multiple instanced `Halite::Client`. [#72](https://github.com/icyleaf/halite/issues/72) (thanks @[qszhu](https://github.com/qszhu))

## [0.10.1] (2019-05-28)

### Fixed

- Fixed duplica query and backslash when reuse client. [#67](https://github.com/icyleaf/halite/pull/67), [#68](https://github.com/icyleaf/halite/issues/68) (thanks @[watzon](https://github.com/watzon))
- Fixed no effect to call `logging(true)` method in Crystal 0.28. [#69](https://github.com/icyleaf/halite/issues/69)

## [0.10.0] (2019-05-20)

### Added

- Add `endpoint` chainable method, also add it as configuration option to reuse client. [#66](https://github.com/icyleaf/halite/pull/66)

## [0.9.2] (2019-05-20)

### Fixed

- Compatibility with Crystal 0.28.0

### Changed

- Drop Crystal 0.25.x, 0.26.x, 0.27.x support.

## [0.9.1] (2019-01-14)

> Minor typo fix (same as v0.9.0)

### Fixed

- Correct version both in `shard.yml` and `version.cr`. (thanks @[matthewmcgarvey](https://github.com/matthewmcgarvey))
- Update basic auth example in `README.md`. (thanks @[matthewmcgarvey](https://github.com/matthewmcgarvey))

## [0.9.0] (2018-12-21)

> New features with performance improved.

### Added

- Add streaming requests (feature to store binary data chunk by chunk) [#53](https://github.com/icyleaf/halite/pull/53)
- Add `user_agent` to Chainable methods. [#55](https://github.com/icyleaf/halite/pull/55)

### Fixed

- Fix overwrite the value with default headers when use `merge` or  `merge!` method in `Halite::Options`. [#54](https://github.com/icyleaf/halite/pull/54)

### Changed

- Remove default headers in `Halite::Options`.
- Move header `User-Agent` to `Halite::Request`.
- Change header `Connection` from "keep-alive" to "close" to `Halite::Request`.
- Remove header `Accept`.

## [0.8.0] (2018-11-30)

> Compatibility with Crystal 0.27 and serious bugfix.

### Changed

- **[breaking changing]** Rename `logger` to `logging`, `with_logger` to `with_logging`. [#52](https://github.com/icyleaf/halite/pull/52)
- **[breaking changing]** Remove `logging` argument in `Halite::Options.new` and `Halite::Client.new`. [#51](https://github.com/icyleaf/halite/pull/51)
- **[breaking changing]** Remove `logging?` method in `Halite::Options`, use `logging` method instead. [#51](https://github.com/icyleaf/halite/pull/51)
- Change `logging` behavior check if features is exists any class of superclasses is `Halite::Logging` instead of given a Bool type.
- Rename prefix `X-Cache` to `X-Halite-Cache` in cache feature.

### Added

- Allow `timeout` method passed single `read` or `connect` method.
- Add `merge!` and `dup` methods in `Halite::Options`. [#51](https://github.com/icyleaf/halite/pull/51)

### Fixed

- Fix duplice add "Content-Type" into header during request. [#50](https://github.com/icyleaf/halite/pull/50)
- Fix non overwrite value of headers use `Halite::Options.merge` method. [#50](https://github.com/icyleaf/halite/pull/50)
- Fix always overwrite and return merged option in a instanced class(session mode), see updated note in [Session](https://github.com/icyleaf/halite#sessions).

### Tested

- Compatibility with Crystal 0.27
- Add specs with Crystal 0.25, 0.26 and 0.27 in Circle CI.

## [0.7.5] (2018-10-31)

### Changed

- **[breaking changing]** Rename argument name `ssl` to `tls` in `Halite::Client`/`Halite::Options`/`Halite::Chainable`.

### Fixed

- Fix new a `Halite::Client` instance with empty block return `Nil`. [#44](https://github.com/icyleaf/halite/issues/44)

## [0.7.4] (2018-10-30)

### Fixed

- Fix typos in document and comments. [#43](https://github.com/icyleaf/halite/issues/43) (thanks @[GloverDonovan](https://github.com/GloverDonovan))

## [0.7.3] (2018-10-18)

### Fixed

- Fix json payloads with sub hash/array/namedtupled. [#41](https://github.com/icyleaf/halite/issues/41) (thanks @[fusillicode](https://github.com/fusillicode))

## [0.7.2] (2018-09-14)

> Minor bugfix :bug:

### Changed

- **[breaking changing]** Renamed `#to_h` to `#to_flat_h` to avoid confict in `HTTP::Params` extension. [#39](https://github.com/icyleaf/halite/issues/39)

### Fixed

- Fix cast from NamedTuple(work: String) to Halite::Options::Type failed with params/json/form. [#38](https://github.com/icyleaf/halite/issues/38)

## [0.7.1] (2018-09-04)

### Changed

- Return empty hash for an empty named tuple.

### Fixed

- Fix send cookie during requesting in session mode. (thanks @[megatux](https://github.com/megatux))
- Fix pass current options instead of instance variable.
- Fix move named tuple extension to src path.

## [0.7.0] (2018-09-03)

> Features support :tada:

### Changed

- **[breaking changing]** Change instance `Halite::Client` with block behavior. [#33](https://github.com/icyleaf/halite/issues/33)
- **[breaking changing]** Renamed argument name `adapter` to `format` in `#logger` chainable method.
- Move logger into features.

### Added

- Add features (aka middleware) support, you can create monitor or interceptor. [#29](https://github.com/icyleaf/halite/issues/29)
- Add cache feature. [#24](https://github.com/icyleaf/halite/issues/24)
- Add `#logging` in chainable method.

### Fixed

- Add misisng `#request` method with headers, params, form, json, raw, ssl arguments.
- Fix do not overwrite default headers with exists one by using `Halite::Options.merge`.
- Fix append response to history only with redirect uri. (thanks @[j8r](https://github.com/j8r))
- Typo and correct words in README. (thanks @[megatux](https://github.com/megatux))

## [0.6.0] (2018-08-24)

> Improve performance with :see_no_evil:

### Changed

- **[breaking changing]** Set `logger` to nil when instance a `Halite::Options`, it throws a `Halite::Error` exception if enable `logging`.
- Change `Halite::Options` accepts argument inside. no effect for users. [#27](https://github.com/icyleaf/halite/pull/27)
- Wrap all exception class into a module, better for reading document.

### Fixed

- Fix always return `#` with `#full_path` if fragment not exists in `Halite::Request`.
- Fix always overwrite with default headers with `#merge` in `Halite::Options`

### Tested

- Compatibility with Crystal 0.26

## [0.5.0] (2018-07-03)

### Changed

- New logger system and json logger support, see [#19](https://github.com/icyleaf/halite/pull/19).
- **[breaking changing]** Change verb request behavior:
  - `get`, `head` only accepts `#params` argument.
  - `post`, `put`, `delete`, `patch`, `options` accepts `#params`, `#form`, `#json` and `#raw` arguments.

### Added

- Add request [#raw](https://github.com/icyleaf/halite/#raw-string) string support. [#20](https://github.com/icyleaf/halite/issues/20) (thanks @[wirrareka](https://github.com/wirrareka))

## [0.4.0] (2018-06-27)

### Changed

- **[breaking changing]** Remove `#mime_type` duplicate with `#content_type` in `Halite::Response`.
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
- Fix `#domain` in `Halite::Request` with subdomain. [#17](https://github.com/icyleaf/halite/pull/17) (thanks @[007lva](https://github.com/007lva))
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

[Unreleased]: https://github.com/icyleaf/halite/compare/v0.11.0...HEAD
[0.11.0]: https://github.com/icyleaf/halite/compare/v0.10.9...v0.11.0
[0.10.9]: https://github.com/icyleaf/halite/compare/v0.10.8...v0.10.9
[0.10.8]: https://github.com/icyleaf/halite/compare/v0.10.7...v0.10.8
[0.10.7]: https://github.com/icyleaf/halite/compare/v0.10.6...v0.10.7
[0.10.6]: https://github.com/icyleaf/halite/compare/v0.10.5...v0.10.6
[0.10.5]: https://github.com/icyleaf/halite/compare/v0.10.4...v0.10.5
[0.10.4]: https://github.com/icyleaf/halite/compare/v0.10.3...v0.10.4
[0.10.3]: https://github.com/icyleaf/halite/compare/v0.10.2...v0.10.3
[0.10.2]: https://github.com/icyleaf/halite/compare/v0.10.1...v0.10.2
[0.10.1]: https://github.com/icyleaf/halite/compare/v0.10.0...v0.10.1
[0.10.0]: https://github.com/icyleaf/halite/compare/v0.9.2...v0.10.0
[0.9.2]: https://github.com/icyleaf/halite/compare/v0.9.1...v0.9.2
[0.9.1]: https://github.com/icyleaf/halite/compare/v0.9.0...v0.9.1
[0.9.0]: https://github.com/icyleaf/halite/compare/v0.8.0...v0.9.0
[0.8.0]: https://github.com/icyleaf/halite/compare/v0.7.5...v0.8.0
[0.7.5]: https://github.com/icyleaf/halite/compare/v0.7.4...v0.7.5
[0.7.4]: https://github.com/icyleaf/halite/compare/v0.7.3...v0.7.4
[0.7.3]: https://github.com/icyleaf/halite/compare/v0.7.2...v0.7.3
[0.7.2]: https://github.com/icyleaf/halite/compare/v0.7.1...v0.7.2
[0.7.1]: https://github.com/icyleaf/halite/compare/v0.7.0...v0.7.1
[0.7.0]: https://github.com/icyleaf/halite/compare/v0.6.0...v0.7.0
[0.6.0]: https://github.com/icyleaf/halite/compare/v0.5.0...v0.6.0
[0.5.0]: https://github.com/icyleaf/halite/compare/v0.4.0...v0.5.0
[0.4.0]: https://github.com/icyleaf/halite/compare/v0.3.2...v0.4.0
[0.3.2]: https://github.com/icyleaf/halite/compare/v0.3.1...v0.3.2
[0.3.1]: https://github.com/icyleaf/halite/compare/v0.2.0...v0.3.1
[0.2.0]: https://github.com/icyleaf/halite/compare/v0.1.5...v0.2.0
[0.1.5]: https://github.com/icyleaf/halite/compare/v0.1.3...v0.1.5
[0.1.3]: https://github.com/icyleaf/halite/compare/v0.1.2...v0.1.3
