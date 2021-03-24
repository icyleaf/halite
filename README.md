![halite-logo](https://github.com/icyleaf/halite/raw/master/halite-logo-small.png)

# Halite

[![Language](https://img.shields.io/badge/language-crystal-776791.svg)](https://github.com/crystal-lang/crystal)
[![Tag](https://img.shields.io/github/tag/icyleaf/halite.svg)](https://github.com/icyleaf/halite/blob/master/CHANGELOG.md)
[![Source](https://img.shields.io/badge/source-github-brightgreen.svg)](https://github.com/icyleaf/halite/)
[![Document](https://img.shields.io/badge/document-api-brightgreen.svg)](https://icyleaf.github.io/halite/)
[![Build Status](https://github.com/icyleaf/halite/workflows/Linux%20CI/badge.svg)](https://github.com/icyleaf/halite/actions?query=workflow%3A%22Linux+CI%22)

HTTP Requests with a chainable REST API, built-in sessions and middleware written by [Crystal](https://crystal-lang.org/).
Inspired from the **awesome** Ruby's [HTTP](https://github.com/httprb/http)/[RESTClient](https://github.com/rest-client/rest-client)
and Python's [requests](https://github.com/requests/requests).

Build in Crystal version `>= 1.0.0`, this document valid with latest commit.

## Index

<!-- TOC -->

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
    - [Auth](#auth)
    - [User Agent](#user-agent)
    - [Headers](#headers)
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
- [Middleware](#middleware)
  - [Write a simple feature](#write-a-simple-feature)
  - [Write a interceptor](#write-a-interceptor)
- [Advanced Usage](#advanced-usage)
  - [Configuring](#configuring)
  - [Endpoint](#endpoint)
  - [Sessions](#sessions)
  - [Streaming Requests](#streaming-requests)
  - [Logging](#logging)
  - [Local Cache](#local-cache)
  - [Link Headers](#link-headers)
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

# Also support Hash as query params
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

Many other HTTP methods are available as well:

- `get`
- `head`
- `post`
- `put`
- `delete`
- `patch`
- `options`

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

Multiple files can also be uploaded using both ways above, it depend on web server.

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

#### Auth

Use the `#basic_auth` method to perform [HTTP Basic Authentication](http://tools.ietf.org/html/rfc2617) using a username and password:

```crystal
Halite.basic_auth(user: "user", pass: "p@ss").get("http://httpbin.org/get")

# We can pass a raw authorization header using the auth method:
Halite.auth("Bearer dXNlcjpwQHNz").get("http://httpbin.org/get")
```

#### User Agent

Use the `#user_agent` method to overwrite default one:

```crystal
Halite.user_agent("Crystal Client").get("http://httpbin.org/user-agent")
```

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

##### 2. Use the `headers` argument in the available request method:

```crystal
Halite.get("http://httpbin.org/anything" , headers: { private_token: "T0k3n" })

Halite.post("http://httpbin.org/anything" , headers: { private_token: "T0k3n" })
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
We can disable it to set `:strict` to `false` if we want any method(verb) requests, in which case the `GET` method(verb) will be used for
that redirect:

```crystal
Halite.follow(strict: false)
      .post("http://httpbin.org/relative-redirect/5")
```

##### History

`Response#history` property list contains the `Response` objects that were created in order to complete the request.
The list is ordered from the oldest to most recent response.

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

**NOTE**: It contains the `Response` object if you use `history` and HTTP was not a `30x`, For example:

```crystal
r = Halite.get("http://httpbin.org/get")
r.history.size # => 0

r = Halite.follow
          .get("http://httpbin.org/get")
r.history.size # => 1
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
tls = OpenSSL::SSL::Context::Client.new
tls.ca_certificates = File.expand_path("~/client.crt")
tls.private_key = File.expand_path("~/client.key")

Halite.get("https://httpbin.org/anything", tls: tls)
```

### Response Handling

After an HTTP request, `Halite::Response` object have several useful methods. (Also see the [API documentation](https://icyleaf.github.io/halite/Halite/Response.html)).

- **#body**: The response body.
- **#body_io**: The response body io only available in streaming requests.
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
we can inherit `Halite::MimeTypes::Adapter` to make our adapter:

```crystal
# Define a MIME type adapter
class YAMLAdapter < Halite::MimeType::Adapter
  def decode(string)
    YAML.parse(string)
  end

  def encode(obj)
    obj.to_yaml
  end
end

# Register to Halite to invoke
Halite::MimeType.register YAMLAdapter.new, "application/x-yaml", "yaml", "yml"

# Test it!
r = Halite.get "https://raw.githubusercontent.com/icyleaf/halite/master/shard.yml"
r.parse("yaml") # or "yml"
# => {"name" => "halite", "version" => "0.4.0", "authors" => ["icyleaf <icyleaf.cn@gmail.com>"], "crystal" => "0.25.0", "license" => "MIT"}
```

#### Binary Data

Store binary data (eg, `application/octet-stream`) to file, you can use [streaming requests](#streaming-requests):

```crystal
Halite.get("https://github.com/icyleaf/halite/archive/master.zip") do |response|
  filename = response.filename || "halite-master.zip"
  File.open(filename, "w") do |file|
    IO.copy(response.body_io, file)
  end
end
```

### Error Handling

- For any status code, a `Halite::Response` will be returned.
- If request timeout, a `Halite::TimeoutError` will be raised.
- If a request exceeds the configured number of maximum redirections, a `Halite::TooManyRedirectsError` will raised.
- If request uri is http and configured tls context, a `Halite::RequestError` will raised.
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
    p "[#{ex.status_code}] #{ex.status_message} (#{ex.class})"
  end
end

# => "[404] not found error with url: https://httpbin.org/status/404 (Halite::Exception::ClientError)"
# => "[500] internal server error error with url: https://httpbin.org/status/500?foo=bar (Halite::Exception::ServerError)"
# => ""
```

## Middleware

Halite now has middleware (a.k.a features) support providing a simple way to plug in intermediate custom logic
in your HTTP client, allowing you to monitor outgoing requests, incoming responses, and use it as an interceptor.

Available features:

- [Logging](#logging) (Yes, logging is based on feature, cool, aha!)
- [Local Cache](#local-cache) (local storage, speed up in development)

### Write a simple feature

Let's implement simple middleware that prints each request:

```crystal
class RequestMonister < Halite::Feature
  @label : String
  def initialize(**options)
    @label = options.fetch(:label, "")
  end

  def request(request) : Halite::Request
    puts @label
    puts request.verb
    puts request.uri
    puts request.body

    request
  end

  Halite.register_feature "request_monster", self
end
```

Then use it in Halite:

```crystal
Halite.use("request_monster", label: "testing")
      .post("http://httpbin.org/post", form: {name: "foo"})

# Or configure to client
client = Halite::Client.new do
  use "request_monster", label: "testing"
end

client.post("http://httpbin.org/post", form: {name: "foo"})

# => testing
# => POST
# => http://httpbin.org/post
# => name=foo
```

### Write a interceptor

Halite's killer feature is the **interceptor**, Use `Halite::Feature::Chain` to process with two result:

- `next`: perform and run next interceptor
- `return`: perform and return

So, you can intercept and turn to the following registered features.

```crystal
class AlwaysNotFound < Halite::Feature
  def intercept(chain)
    response = chain.perform
    response = Halite::Response.new(chain.request.uri, 404, response.body, response.headers)
    chain.next(response)
  end

  Halite.register_feature "404", self
end

class PoweredBy < Halite::Feature
  def intercept(chain)
    if response = chain.response
      response.headers["X-Powered-By"] = "Halite"
      chain.return(response)
    else
      chain
    end
  end

  Halite.register_feature "powered_by", self
end

r = Halite.use("404").use("powered_by").get("http://httpbin.org/user-agent")
r.status_code               # => 404
r.headers["X-Powered-By"]   # => Halite
r.body                      # => {"user-agent":"Halite/0.6.0"}
```

For more implementation details about the feature layer, see the [Feature](https://github.com/icyleaf/halite/blob/master/src/halite/feature.cr#L2) class and [examples](https://github.com/icyleaf/halite/tree/master/src/halite/features) and [specs](https://github.com/icyleaf/halite/blob/master/spec/spec_helper.cr#L23).

## Advanced Usage

### Configuring

Halite provides a traditional way to instance client, and you can configure any chainable methods with block:

```crystal
client = Halite::Client.new do
  # Set basic auth
  basic_auth "username", "password"

  # Enable logging
  logging true

  # Set timeout
  timeout 10.seconds

  # Set user agent
  headers user_agent: "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_12_6) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/62.0.3202.94 Safari/537.36"
end

# You also can configure in this way
client.accept("application/json")

r = client.get("http://httpbin.org/get")
```

### Endpoint

No more given endpoint per request, use `endpoint` will make the request URI shorter, you can set it in flexible way:

```crystal
client = Halite::Client.new do
  endpoint "https://gitlab.org/api/v4"
  user_agent "Halite"
end

client.get("users")       # GET https://gitlab.org/api/v4/users

# You can override the path by using an absolute path
client.get("/users")      # GET https://gitlab.org/users
```

### Sessions

As like [requests.Session()](http://docs.python-requests.org/en/master/user/advanced/#session-objects), Halite built-in session by default.

Let's persist some cookies across requests:

```crystal
client = Halite::Client.new
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

Note, however, that chainable methods will not be persisted across requests, even if using a session. This example will only send the cookies or headers with the first request, but not the second:

```crystal
client = Halite::Client.new
r = client.cookies("username": "foobar").get("http://httpbin.org/cookies")
r.body # => {"cookies":{"username":"foobar"}}

r = client.get("http://httpbin.org/cookies")
r.body # => {"cookies":{}}
```

If you want to manually add cookies, headers (even features etc) to your session, use the methods start with `with_` in `Halite::Options`
to manipulate them:

```crystal
r = client.get("http://httpbin.org/cookies")
r.body # => {"cookies":{}}

client.options.with_cookie("username": "foobar")
r = client.get("http://httpbin.org/cookies")
r.body # => {"cookies":{"username":"foobar"}}
```

### Streaming Requests

Similar to [HTTP::Client](https://crystal-lang.org/api/0.36.1/HTTP/Client.html#streaming) usage with a block,
you can easily use same way, but Halite returns a `Halite::Response` object:

```crystal
r = Halite.get("http://httpbin.org/stream/5") do |response|
  response.status_code                  # => 200
  response.body_io.each_line do |line|
    puts JSON.parse(line)               # => {"url" => "http://httpbin.org/stream/5", "args" => {}, "headers" => {"Host" => "httpbin.org", "Connection" => "close", "User-Agent" => "Halite/0.8.0", "Accept" => "*/*", "Accept-Encoding" => "gzip, deflate"}, "id" => 0_i64}
  end
end
```

> **Warning**:
>
> `body_io` is avaiabled as an `IO` and not reentrant safe. Might throws a "Nil assertion failed" exception if there is no data in the `IO`
(such like `head` requests). Calling this method multiple times causes some of the received data being lost.
>
> One more thing, use streaming requests the response will always [enable redirect](#redirects-and-history) automatically.

### Logging

Halite does not enable logging on each request and response too.
We can enable per operation logging by configuring them through the chaining API.

By default, Halite will logging all outgoing HTTP requests and their responses(without binary stream) to `STDOUT` on DEBUG level.
You can configuring the following options:

- `logging`: Instance your `Halite::Logging::Abstract`, check [Use the custom logging](#use-the-custom-logging).
- `format`: Output format, built-in `common` and `json`, you can write your own.
- `file`: Write to file with path, works with `format`.
- `filemode`: Write file mode, works with `format`, by default is `a`. (append to bottom, create it if file is not exist)
- `skip_request_body`: By default is `false`.
- `skip_response_body`: By default is `false`.
- `skip_benchmark`: Display elapsed time, by default is `false`.
- `colorize`: Enable colorize in terminal, only apply in `common` format, by default is `true`.

> **NOTE**: `format` (`file` and `filemode`) and `logging` are conflict, you can not use both.

Let's try with it:

```crystal
# Logging json request
Halite.logging
      .get("http://httpbin.org/get", params: {name: "foobar"})

# => 2018-06-25 18:33:14 +08:00 | request  | GET    | http://httpbin.org/get?name=foobar
# => 2018-06-25 18:33:15 +08:00 | response | 200    | http://httpbin.org/get?name=foobar | 381.32ms | application/json
# => {"args":{"name":"foobar"},"headers":{"Accept":"*/*","Accept-Encoding":"gzip, deflate","Connection":"close","Host":"httpbin.org","User-Agent":"Halite/0.3.2"},"origin":"60.206.194.34","url":"http://httpbin.org/get?name=foobar"}

# Logging image request
Halite.logging
      .get("http://httpbin.org/image/png")

# => 2018-06-25 18:34:15 +08:00 | request  | GET    | http://httpbin.org/image/png
# => 2018-06-25 18:34:15 +08:00 | response | 200    | http://httpbin.org/image/png | image/png

# Logging with options
Halite.logging(skip_request_body: true, skip_response_body: true)
      .post("http://httpbin.org/get", form: {image: File.open("halite-logo.png")})

# => 2018-08-28 14:33:19 +08:00 | request  | POST   | http://httpbin.org/post
# => 2018-08-28 14:33:21 +08:00 | response | 200    | http://httpbin.org/post | 1.61s | application/json
```

#### JSON-formatted logging

It has JSON formatted for developer friendly logging.

```
Halite.logging(format: "json")
      .get("http://httpbin.org/get", params: {name: "foobar"})
```

#### Write to a log file

```crystal
# Write plain text to a log file
Log.setup("halite.file", backend: Log::IOBackend.new(File.open("/tmp/halite.log", "a")))
Halite.logging(for: "halite.file", skip_benchmark: true, colorize: false)
      .get("http://httpbin.org/get", params: {name: "foobar"})

# Write json data to a log file
Log.setup("halite.file", backend: Log::IOBackend.new(File.open("/tmp/halite.log", "a")))
Halite.logging(format: "json", for: "halite.file")
      .get("http://httpbin.org/get", params: {name: "foobar"})

# Redirect *all* logging from Halite to a file:
Log.setup("halite", backend: Log::IOBackend.new(File.open("/tmp/halite.log", "a")))
```

#### Use the custom logging

Creating the custom logging by integration `Halite::Logging::Abstract` abstract class.
Here has two methods must be implement: `#request` and `#response`.

```crystal
class CustomLogging < Halite::Logging::Abstract
  def request(request)
    @logger.info { "| >> | %s | %s %s" % [request.verb, request.uri, request.body] }
  end

  def response(response)
    @logger.info { "| << | %s | %s %s" % [response.status_code, response.uri, response.content_type] }
  end
end

# Add to adapter list (optional)
Halite::Logging.register "custom", CustomLogging.new

Halite.logging(logging: CustomLogging.new)
      .get("http://httpbin.org/get", params: {name: "foobar"})

# We can also call it use format name if you added it.
Halite.logging(format: "custom")
      .get("http://httpbin.org/get", params: {name: "foobar"})

# => 2017-12-13 16:40:13 +08:00 | >> | GET | http://httpbin.org/get?name=foobar
# => 2017-12-13 16:40:15 +08:00 | << | 200 | http://httpbin.org/get?name=foobar application/json
```

### Local Cache

Local cache feature is caching responses easily with Halite through an chainable method that is simple and elegant
yet powerful. Its aim is to focus on the HTTP part of caching and do not worrying about how stuff stored, api rate limiting
even works without network(offline).

It has the following options:

- `file`: Load cache from file. it conflict with `path` and `expires`.
- `path`: The path of cache, default is "/tmp/halite/cache/"
- `expires`: The expires time of cache, default is never expires.
- `debug`: The debug mode of cache, default is `true`

With debug mode, cached response it always included some headers information:

- `X-Halite-Cached-From`: Cache source (cache or file)
- `X-Halite-Cached-Key`: Cache key with verb, uri and body (return with cache, not `file` passed)
- `X-Halite-Cached-At`:  Cache created time
- `X-Halite-Cached-Expires-At`: Cache expired time (return with cache, not `file` passed)

```crystal
Halite.use("cache").get "http://httpbin.org/anything"     # request a HTTP
r = Halite.use("cache").get "http://httpbin.org/anything" # request from local storage
r.headers                                                 # => {..., "X-Halite-Cached-At" => "2018-08-30 10:41:14 UTC", "X-Halite-Cached-By" => "Halite", "X-Halite-Cached-Expires-At" => "2018-08-30 10:41:19 UTC", "X-Halite-Cached-Key" => "2bb155e6c8c47627da3d91834eb4249a"}}
```

### Link Headers

Many HTTP APIs feature [Link headers](https://tools.ietf.org/html/rfc5988). GitHub uses
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

All [Contributors](https://github.com/icyleaf/halite/graphs/contributors) are on the wall.

## You may also like

- [totem](https://github.com/icyleaf/totem) - Load and parse a configuration file or string in JSON, YAML, dotenv formats.
- [markd](https://github.com/icyleaf/markd) - Yet another markdown parser built for speed, Compliant to CommonMark specification.
- [poncho](https://github.com/icyleaf/poncho) - A .env parser/loader improved for performance.
- [popcorn](https://github.com/icyleaf/popcorn) - Easy and Safe casting from one type to another.
- [fast-crystal](https://github.com/icyleaf/fast-crystal) - 💨 Writing Fast Crystal 😍 -- Collect Common Crystal idioms.

## License

[MIT License](https://github.com/icyleaf/halite/blob/master/LICENSE) © icyleaf
