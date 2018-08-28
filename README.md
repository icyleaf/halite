![halite-logo](https://github.com/icyleaf/halite/raw/master/halite-logo-small.png)

# Halite

[![Language](https://img.shields.io/badge/language-crystal-776791.svg)](https://github.com/crystal-lang/crystal)
[![Tag](https://img.shields.io/github/tag/icyleaf/halite.svg)](https://github.com/icyleaf/halite/blob/master/CHANGELOG.md)
[![Build Status](https://img.shields.io/circleci/project/github/icyleaf/halite/master.svg?style=flat)](https://circleci.com/gh/icyleaf/halite)

Crystal HTTP Requests with a chainable REST API, built-in sessions and loggers written by [Crystal](https://crystal-lang.org/).
Inspired from the **awesome** Ruby's [HTTP](https://github.com/httprb/http)/[RESTClient](https://github.com/rest-client/rest-client) gem
and Python's [requests](https://github.com/requests/requests).

Build in crystal version >= `v0.25.0`, documents generated in latest commit.

## Index

<!-- TOC -->

- [Index](#index)
- [Installation](#installation)
- [Usage](#usage)
  - [Making Requests](#making-requests)
  - [Passing Parameters](#passing-parameters)
    - [Query string parameters](#query-string-parameters)
    - [Form data](#form-data)
    - [File uploads (via form data)](#file-uploads-via-form-data)
    - [JSON data](#json-data)
    - [Raw String](#raw-string)
  - [Passing advanced options](#passing-advanced-options)
    - [Headers](#headers)
    - [Auth](#auth)
    - [Cookies](#cookies)
    - [Redirects and History](#redirects-and-history)
    - [Timeout](#timeout)
  - [HTTPS](#https)
  - [Response Handling](#response-handling)
    - [Response Content](#response-content)
    - [JSON Content](#json-content)
    - [Parsing Content](#parsing-content)
    - [Binary Data](#binary-data)
  - [Error Handling](#error-handling)
    - [Raise for status code](#raise-for-status-code)
- [Advanced Usage](#advanced-usage)
  - [Sessions](#sessions)
  - [Logging](#logging)
    - [Simple logging](#simple-logging)
    - [Logging request only](#logging-request-only)
    - [JSON-formatted logging](#json-formatted-logging)
    - [Write to a log file](#write-to-a-log-file)
    - [Use the custom logger](#use-the-custom-logger)
  - [Link Headers](#link-headers)
- [Help and Discussion](#help-and-discussion)
- [Donate](#donate)
- [How to Contribute](#how-to-contribute)
- [License](#license)

<!-- /TOC -->

## Installation

Add this to your application's `shard.yml`:

```yaml
dependencies:
  halite:
    github: icyleaf/halite
```

## Usage

```crystal
require "halite"
```

### Making Requests

Make a GET request:

```crystal
# Direct get url
Halite.get("http://httpbin.org/get")

# Support NamedTuple as query params
Halite.get("http://httpbin.org/get", params: {
  language: "crystal",
  shard: "halite"
})

# Also support Array as query params
Halite.get("http://httpbin.org/get", headers: {
    "Private-Token" => "T0k3n"
  }, params: {
    "language" => "crystal",
    "shard" => "halite"
  })

# And support chainable
Halite.header(private_token: "T0k3n")
      .get("http://httpbin.org/get", params: {
        "language" => "crystal",
        "shard" => "halite"
      })
```

See also all [chainable methods](https://icyleaf.github.io/halite/Halite/Chainable.html).

Many other HTTP methods are avaiabled as well:

- `get`
- `head`
- `post`
- `put`
- `delete`
- `patch`
- `options`

```crystal
Halite.get("http://httpbin.org/get", params: { "firstname" => "Olen", "lastname" => "Rosenbaum" })

Halite.head("http://httpbin.org/anything", params: { "firstname" => "Olen", "lastname" => "Rosenbaum" })

Halite.post("http://httpbin.org/post", form: { "firstname" => "Olen", "lastname" => "Rosenbaum" })

Halite.put("http://httpbin.org/put", json: { "firstname" => "Olen", "lastname" => "Rosenbaum" })

Haltie.delete("http://httpbin.org/delete", params: { "user_id" => 234234 })

Halite.patch("http://httpbin.org/anything", json: { "firstname" => "Olen", "lastname" => "Rosenbaum" })

Haltie.options("http://httpbin.org/anything", params: json: { "firstname" => "Olen", "lastname" => "Rosenbaum" })
```

### Passing Parameters

#### Query string parameters

Use the `params` argument to add query string parameters to requests:

```crystal
Halite.get("http://httpbin.org/get", params: { "firstname" => "Olen", "lastname" => "Rosenbaum" })
```

#### Form data

Use the `form` argument to pass data serialized as form encoded:

```crystal
Halite.post("http://httpbin.org/post", form: { "firstname" => "Olen", "lastname" => "Rosenbaum" })
```

#### File uploads (via form data)

To upload files as if form data, construct the form as follows:

```crystal
Halite.post("http://httpbin.org/post", form: {
  "username" => "Quincy",
  "avatar" => File.open("/Users/icyleaf/quincy_avatar.png")
})
```

It is possible to upload multiple files:

```crystal
Halite.post("http://httpbin.org/post", form: {
  photos: [
    File.open("/Users/icyleaf/photo1.png"),
    File.open("/Users/icyleaf/photo2.png")
  ],
  album_name: "samples"
})
```

Or pass the name with `[]`:

```crystal
Halite.post("http://httpbin.org/post", form: {
  "photos[]" => [
    File.open("/Users/icyleaf/photo1.png"),
    File.open("/Users/icyleaf/photo2.png")
  ],
  "album_name" => "samples"
})
```

Multiple files aslo can be uploaded using both ways above, it depend on web server.

#### JSON data

Use the `json` argument to pass data serialized as body encoded:

```crystal
Halite.post("http://httpbin.org/post", json: { "firstname" => "Olen", "lastname" => "Rosenbaum" })
```

#### Raw String

Use the `raw` argument to pass raw string as body and set the `Content-Type` manually:

```crystal
# Set content-type to "text/plain" by default
Halite.post("http://httpbin.org/post", raw: "name=Peter+Lee&address=%23123+Happy+Ave&language=C%2B%2B")

# Set content-type manually
Halite.post("http://httpbin.org/post",
  headers: {
    "content-type" => "application/json"
  },
  raw: %Q{{"name":"Peter Lee","address":"23123 Happy Ave","language":"C++"}}
)
```

### Passing advanced options

#### Headers

Here are two way to passing headers data:

##### 1. Use the `#headers` method

```crystal
Halite.headers(private_token: "T0k3n").get("http://httpbin.org/get")

# Also support Hash or NamedTuple
Halite.headers({ "private_token" => "T0k3n" }).get("http://httpbin.org/get")

# Or
Halite.headers({ private_token: "T0k3n" }).get("http://httpbin.org/get")
```

##### 2. Use the `headers` argument in availabled request method:

```crystal
Halite.get("http://httpbin.org/anything" , headers: { private_token: "T0k3n" })

Halite.post("http://httpbin.org/anything" , headers: { private_token: "T0k3n" })
```

#### Auth

Use the `#basic_auth` method to perform [HTTP Basic Authentication](http://tools.ietf.org/html/rfc2617) using a username and password:

```crystal
Halite.basic_auth(user: "user", password: "p@ss").get("http://httpbin.org/get")

# We can pass a raw authorization header using the auth method:
Halite.auth("Bearer dXNlcjpwQHNz").get("http://httpbin.org/get")
```

#### Cookies

##### Passing cookies in requests

The `Halite.cookies` option can be used to configure cookies for a given request:

```crystal
Halite.cookies(session_cookie: "6abaef100b77808ceb7fe26a3bcff1d0")
      .get("http://httpbin.org/headers")
```

##### Get cookies in requests

To obtain the cookies(cookie jar) for a given response, call the `#cookies` method:

```crystal
r = Halite.get("http://httpbin.org/cookies?set?session_cookie=6abaef100b77808ceb7fe26a3bcff1d0")
pp r.cookies
# => #<HTTP::Cookies:0x10dbed980 @cookies={"session_cookie" =>#<HTTP::Cookie:0x10ec20f00 @domain=nil, @expires=nil, @extension=nil, @http_only=false, @name="session_cookie", @path="/", @secure=false, @value="6abaef100b77808ceb7fe26a3bcff1d0">}>
```

#### Redirects and History

##### Automatically following redirects

The `Halite.follow` method can be used for automatically following redirects(Max up to 5 times):

```crystal
# Set the cookie and redirect to http://httpbin.org/cookies
Halite.follow
      .get("http://httpbin.org/cookies/set/name/foo")
```

##### Limiting number of redirects

As above, set over 5 times, it will raise a `Halite::TooManyRedirectsError`, but you can change less if you can:

```crystal
Halite.follow(2)
      .get("http://httpbin.org/relative-redirect/5")
```

##### Disabling unsafe redirects

It only redirects with `GET`, `HEAD` request and returns a `300`, `301`, `302` by default, otherwise it will raise a `Halite::StateError`.
We can diasble it to set `:strict` to `false` if we want any method(verb) requests, in which case the `GET` method(verb) will be used for
that redirect:

```crystal
Halite.follow(strict: false)
      .post("http://httpbin.org/relative-redirect/5")
```

##### History

`Response#history` property list contains the `Response` objects that were created in order to complete the request.
The list is orderd from the orderst to the most recent response.

```crystal
r = Halite.follow
          .get("http://httpbin.org/redirect/3")

r.uri
# => http://httpbin.org/get

r.status_code
# => 200

r.history
# => [
#      #<Halite::Response HTTP/1.1 302 FOUND {"Location" => "/relative-redirect/2" ...>,
#      #<Halite::Response HTTP/1.1 302 FOUND {"Location" => "/relative-redirect/1" ...>,
#      #<Halite::Response HTTP/1.1 302 FOUND {"Location" => "/get" ...>,
#      #<Halite::Response HTTP/1.1 200 OK    {"Content-Type" => "application/json" ...>
#    ]
```

#### Timeout

By default, the Halite does not enforce timeout on a request.
We can enable per operation timeouts by configuring them through the chaining API.

The `connect` timeout is the number of seconds Halite will wait for our client to establish a connection to a remote server call on the socket.

Once our client has connected to the server and sent the HTTP request,
the `read` timeout is the number of seconds the client will wait for the server to send a response.

```crystal
# Separate set connect and read timeout
Halite.timeout(connect: 3.0, read: 2.minutes)
      .get("http://httpbin.org/anything")

# Boath set connect and read timeout
# The timeout value will be applied to both the connect and the read timeouts.
Halite.timeout(5)
      .get("http://httpbin.org/anything")
```

### HTTPS

The Halite supports HTTPS via Crystal's built-in OpenSSL module. All you have to do in order to use HTTPS is pass in an https://-prefixed URL.

To use client certificates, you can pass in a custom `OpenSSL::SSL::Context::Client` object containing the certificates you wish to use:

```crystal
ssl = OpenSSL::SSL::Context::Client.new
ssl.ca_certificates = File.expand_path("~/client.crt")
ssl.private_key = File.expand_path("~/client.key")

Halite.get("https://httpbin.org/anything", ssl: ssl)
```

### Response Handling

After an HTTP request, `Halite::Response` object have several useful methods. (Also see the [API documentation](https://icyleaf.github.io/halite/Halite/Response.html)).

- **#body**: The response body.
- **#body_io**: The response body io.
- **#status_code**: The HTTP status code.
- **#content_type**: The content type of the response.
- **#content_length**: The content length of the response.
- **#cookies**: A `HTTP::Cookies` set by server.
- **#headers**: A `HTTP::Headers` of the response.
- **#links**: A list of `Halite::HeaderLink` set from headers.
- **#parse**: (return value depends on MIME type) parse the body using a parser defined for the `#content_type`.
- **#to_a**: Return a `Hash` of status code, response headers and body as a string.
- **#to_raw**: Return a raw of response as a string.
- **#to_s**: Return response body as a string.
- **#version**: The HTTP version.

#### Response Content

We can read the content of the server's response by call `#body`:

```crystal
r = Halite.get("http://httpbin.org/user-agent")
r.body
# => {"user-agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_13_5) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/67.0.3396.87 Safari/537.36"}
```

The `gzip` and `deflate` transfer-encodings are automatically decoded for you.
And requests will automatically decode content from the server. Most unicode charsets are seamlessly decoded.

#### JSON Content

There’s also a built-in a JSON adapter, in case you’re dealing with JSON data:

```crystal
r = Halite.get("http://httpbin.org/user-agent")
r.parse("json")
r.parse # simplily by default
# => {
# =>   "user-agent" => "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_13_5) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/67.0.3396.87 Safari/537.36"
# => }
```

#### Parsing Content

`Halite::Response` has a MIME type adapter system that you can use a decoder to parse the content,
we can inherit `Halite::Logger::Adapter` make our adapter:

```crystal
# Define a MIME type adapter
class YAMLAdapter < Halite::Logger::Adapter
  def decode(string)
    YAML.parse(string)
  end

  def encode(obj)
    obj.to_yaml
  end
end

# Register to Halite to invoke
Halite::MimeTypes.register_adapter "application/x-yaml", YAMLAdapter.new
Halite::MimeTypes.register_alias "application/x-yaml", "yaml"
Halite::MimeTypes.register_alias "application/x-yaml", "yml"

# Test it!
r = Halite.get "https://raw.githubusercontent.com/icyleaf/halite/master/shard.yml"
r.parse("yaml") # or "yml"
# => {"name" => "halite", "version" => "0.4.0", "authors" => ["icyleaf <icyleaf.cn@gmail.com>"], "crystal" => "0.25.0", "license" => "MIT"}
```

#### Binary Data

Store binary data(`application/octet-stream`) to file, you can do this:

```crystal
r = Halite.get("http://example.com/foo/bar.zip")
filename = r.headers["Content-Disposition"].split("filename=")[1]
File.open(filename, "w") do |f|
  while byte = r.body.read_byte
    f.write_byte byte
  end
end
```

### Error Handling

- For any status code, a `Halite::Response` will be returned.
- If request timeout, a `Halite::TimeoutError` will be raised.
- If a request exceeds the configured number of maximum redirections, a `Halite::TooManyRedirectsError` will raised.
- If request uri is http and configured ssl context, a `Halite::RequestError` will raised.
- If request uri is invalid, a `Halite::ConnectionError`/`Halite::UnsupportedMethodError`/`Halite::UnsupportedSchemeError` will raised.

#### Raise for status code

If we made a bad request(a 4xx client error or a 5xx server error response), we can raise with `Halite::Response.raise_for_status`.

But, since our `status_code` was not `4xx` or `5xx`, it returns `nil` when we call it:

```crystal
urls = [
  "https://httpbin.org/status/404",
  "https://httpbin.org/status/500?foo=bar",
  "https://httpbin.org/status/200",
]

urls.each do |url|
  r = Halite.get url
  begin
    r.raise_for_status
    p r.body
  rescue ex : Halite::ClientError | Halite::ServerError
    p "#{ex.message} (#{ex.class})"
  end
end

# => "404 not found error with url: https://httpbin.org/status/404  (Halite::ClientError)"
# => "500 internal server error error with url: https://httpbin.org/status/500?foo=bar  (Halite::ServerError)"
# => ""
```

## Advanced Usage

### Sessions

As like [requests.Session()](http://docs.python-requests.org/en/master/user/advanced/#session-objects), Halite built-in session by default.

Let's persist some cookies across requests:

```crystal
client = Halite::Client.new
# Or configure it
client = Halite::Client.new do |options|
  options.headers = {
    user_agent: "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_12_6) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/62.0.3202.94 Safari/537.36",
  }

  # Enable logging
  options.logging = true

  # Set read timeout to one minute
  options.read_timeout = 1.minutes
end

client.get("http://httpbin.org/cookies/set?private_token=6abaef100b77808ceb7fe26a3bcff1d0")
client.get("http://httpbin.org/cookies")
# => 2018-06-25 18:41:05 +08:00 | request | GET    | http://httpbin.org/cookies/set?private_token=6abaef100b77808ceb7fe26a3bcff1d0
# => 2018-06-25 18:41:06 +08:00 | response | 302    | http://httpbin.org/cookies/set?private_token=6abaef100b77808ceb7fe26a3bcff1d0 | text/html
# => <!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 3.2 Final//EN">
# => <title>Redirecting...</title>
# => <h1>Redirecting...</h1>
# => <p>You should be redirected automatically to target URL: <a href="/cookies">/cookies</a>.  If not click the link.
# => 2018-06-25 18:41:06 +08:00 | request | GET    | http://httpbin.org/cookies
# => 2018-06-25 18:41:07 +08:00 | response | 200    | http://httpbin.org/cookies | application/json
# => {"cookies":{"private_token":"6abaef100b77808ceb7fe26a3bcff1d0"}}
```

All it support with [chainable methods](https://icyleaf.github.io/halite/Halite/Chainable.html) in the other examples list in [requests.Session](http://docs.python-requests.org/en/master/user/advanced/#session-objects).

### Logging

the Halite does not enable logging on each request and response too.
We can enable per operation logging by configuring them through the chaining API.

#### Simple logging

```crystal
Halite.logger
      .get("http://httpbin.org/get", params: {name: "foobar"})

# => 2018-06-25 18:33:14 +08:00 | request | GET    | http://httpbin.org/get?name=foobar
# => 2018-06-25 18:33:15 +08:00 | response | 200    | http://httpbin.org/get?name=foobar | application/json
# => {"args":{"name":"foobar"},"headers":{"Accept":"*/*","Accept-Encoding":"gzip, deflate","Connection":"close","Host":"httpbin.org","User-Agent":"Halite/0.3.2"},"origin":"60.206.194.34","url":"http://httpbin.org/get?name=foobar"}

Halite.logger
      .get("http://httpbin.org/image/png")

# => 2018-06-25 18:34:15 +08:00 | request | GET    | http://httpbin.org/image/png
# => 2018-06-25 18:34:15 +08:00 | response | 200    | http://httpbin.org/image/png | image/png
```

#### Logging request only

If you want logging request behavior only, throught pass `response` argument to `false`.
And it not output the full body with binary type MIME types, please review it [here](https://github.com/icyleaf/halite/blob/master/src/halite/loggers/common_logger.cr#L79).

```crystal
Halite.logger(response: false)
      .post("http://httpbin.org/get", form: {image: File.open("halite-logo.png")})

# => 2018-06-25 18:39:15 +08:00 | request | POST   | http://httpbin.org/get
# => ---------------------------gUEmO7X80NT4_qIb-kgh4v2z
# => Content-Disposition: form-data; name="image"; filename="halite-logo.png"
# => [image data]
# => ----------------------------gUEmO7X80NT4_qIb-kgh4v2z--
```

#### JSON-formatted logging

It has JSON formatted for developer friendly logger.

```
Halite.logger(adapter: "json")
      .get("http://httpbin.org/get", params: {name: "foobar"})
```

#### Write to a log file

```crystal
# Write plain text to a log file
Halite.logger(filename: "logs/halite.log", response: false)
      .get("http://httpbin.org/get", params: {name: "foobar"})

# Write json data to a log file
Halite.logger(adapter: "json", filename: "logs/halite.log", response: false)
      .get("http://httpbin.org/get", params: {name: "foobar"})
```

#### Use the custom logger

Creating the custom logger by integration `Halite::Logger` abstract class.
here has two methods must be implement: `Halite::Logger.request` and `Halite::Logger.response`.

```crystal
class CustomLogger < Halite::Logger::Adapter
  def request(request)
    @logger.info "| >> | %s | %s %s" % [request.verb, request.uri, request.body]
  end

  def response(response)
    @logger.info "| << | %s | %s %s" % [response.status_code, response.uri, response.content_type]
  end
end

# Add to adapter list (optional)
Halite::Logger.register_adapter "custom", CustomLogger.new

Halite.logger(logger: CustomLogger.new)
      .get("http://httpbin.org/get", params: {name: "foobar"})

# We can also call it use adapter name if we added it.
Halite.logger(adapter: "custom")
      .get("http://httpbin.org/get", params: {name: "foobar"})

# => 2017-12-13 16:40:13 +08:00 | >> | GET | http://httpbin.org/get?name=foobar
# => 2017-12-13 16:40:15 +08:00 | << | 200 | http://httpbin.org/get?name=foobar application/json
```

### Link Headers

Many HTTP APIs feature [Link headers](https://tools.ietf.org/html/rfc5988). Github uses
these for [pagination](https://developer.github.com/v3/#pagination) in their API, for example:

```crystal
r = Halite.get "https://api.github.com/users/icyleaf/repos?page=1&per_page=2"
r.links
# => {"next" =>
# =>   Halite::HeaderLink(
# =>    @params={},
# =>    @rel="next",
# =>    @target="https://api.github.com/user/17814/repos?page=2&per_page=2"),
# =>  "last" =>
# =>   Halite::HeaderLink(
# =>    @params={},
# =>    @rel="last",
# =>    @target="https://api.github.com/user/17814/repos?page=41&per_page=2")}

r.links["next"]
# => "https://api.github.com/user/17814/repos?page=2&per_page=2"

r.links["next"].params
# => {}
```

## Help and Discussion

You can browse the API documents:

https://icyleaf.github.io/halite/

You can browse the all chainable methods:

https://icyleaf.github.io/halite/Halite/Chainable.html

You can browse the Changelog:

https://github.com/icyleaf/halite/blob/master/CHANGELOG.md

If you have found a bug, please create a issue here:

https://github.com/icyleaf/halite/issues/new

## Donate

Halite is a open source, collaboratively funded project. If you run a business and are using Halite in a revenue-generating product,
it would make business sense to sponsor Halite development. Individual users are also welcome to make a one time donation
if Halite has helped you in your work or personal projects.

You can donate via [Paypal](https://www.paypal.me/icyleaf/5).

## How to Contribute

Your contributions are always welcome! Please submit a pull request or create an issue to add a new question, bug or feature to the list.

Here is a throughput graph of the repository for the last few weeks:

[![Throughput Graph](https://graphs.waffle.io/icyleaf/halite/throughput.svg)](https://github.com/icyleaf/halite/issues/)

All [Contributors](https://github.com/icyleaf/halite/graphs/contributors) are on the wall.

## You may also like

- [totem](https://github.com/icyleaf/totem) - Load and parse a configuration file or string in JSON, YAML, dotenv formats.
- [markd](https://github.com/icyleaf/markd) - Yet another markdown parser built for speed, Compliant to CommonMark specification.
- [poncho](https://github.com/icyleaf/poncho) - A .env parser/loader improved for performance.
- [popcorn](https://github.com/icyleaf/popcorn) - Easy and Safe casting from one type to another.
- [fast-crystal](https://github.com/icyleaf/fast-crystal) - 💨 Writing Fast Crystal 😍 -- Collect Common Crystal idioms.

## License

[MIT License](https://github.com/icyleaf/halite/blob/master/LICENSE) © icyleaf
