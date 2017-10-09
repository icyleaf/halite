# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/en/1.0.0/)
and this project adheres to [Semantic Versioning](http://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Todo

- 100% pass specs

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

[Unreleased]: https://github.com/icyleaf/halite/compare/v0.1.3...HEAD
[0.1.3]: https://github.com/icyleaf/halite/compare/v0.1.2...v0.1.3
