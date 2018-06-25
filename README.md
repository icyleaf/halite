![halite-logo](halite-logo-small.png)

# Halite

![Language](https://img.shields.io/badge/language-crystal-776791.svg)
[![Tag](https://img.shields.io/github/tag/icyleaf/halite.svg)](https://github.com/icyleaf/halite/blob/master/CHANGELOG.md)
[![Build Status](https://img.shields.io/circleci/project/github/icyleaf/halite/master.svg?style=flat)](https://circleci.com/gh/icyleaf/halite)
[![License](https://img.shields.io/github/license/icyleaf/halite.svg)](https://github.com/icyleaf/halite/blob/master/LICENSE)

Crystal HTTP Requests with a chainable REST API, built-in sessions and loggers written by [Crystal](https://crystal-lang.org/).
Inspired from the **awesome** Ruby's [HTTP](https://github.com/httprb/http)/[RESTClient](https://github.com/rest-client/rest-client) gem
and Python's [requests](https://github.com/requests/requests).

Build in crystal version >= `v0.25.0`, Docs Generated in latest commit.

## Index

- [Installation](#installation)
- [Usage](#usage)
  - [Making Requests](#making-requests)
  - [Passing Parameters](#passing-parameters)
    - [Query String](#query-string-parameters)
    - [Form data](#form-data)
    - [File uploads](#file-uploads-via-form-data)
    - [JSON data](#json-data)
  - [Passing advanced options](#passing-advanced-options)
    - [Headers](#headers)
    - [Auth](#auth)
    - [Cookies](#cookies)
    - [Redirects and History](#redirects-and-history)
    - [Timeout](#timeout)
  - [HTTPS](#https)
  - [Response Handling](#response-handling)
    - [Binary data](#binary-data)
  - [Error Handling](#error-handling)
- [Advanced Usage](#advanced-usage)
  - [Sessions](#sessions)
  - [Logging](#logging)
- [Help and Discussion](#help-and-discussion)
- [Contributing](#contributing)
- [Contributors](#contributors)

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

Want multiple files upload, of cause:

> NOTE: apply for `master` branch, not release yet.

```crystal
Halite.post("http://httpbin.org/post", form: {
  "photos" => [
    File.open("/Users/icyleaf/photo1.png"),
    File.open("/Users/icyleaf/photo2.png")
  ],
  "album_name" => "samples"
})
```

#### JSON data

Use the `json` argument to pass data serialized as body encoded:

```crystal
Halite.post("http://httpbin.org/post", json: { "firstname" => "Olen", "lastname" => "Rosenbaum" })
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

# You can pass a raw authorization header using the auth method:
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
You can diasble it to set `:strict` to `false` if you want any method(verb) requests, in which case the `GET` method(verb) will be used for
that redirect:

```crystal
Halite.follow(strict: false)
      .post("http://httpbin.org/relative-redirect/5")
```

##### History

`Response#history` property list contains the `Response` objects that were created in order to complete the request. The list is orderd from the orderst to the most recent response.

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

By default, the Halite does not enforce timeout on a request. You can enable per operation timeouts by configuring them through the chaining API.

The `connect` timeout is the number of seconds Halite will wait for your client to establish a connection to a remote server call on the socket.

Once your client has connected to the server and sent the HTTP request, the `read` timeout is the number of seconds the client will wait for the server to send a response.

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
- **#code**: The HTTP status code.
- **#content_type**: The content type of the response.
- **#content_length**: The content length of the response.
- **#cookies**: A `HTTP::Cookies` set by server.
- **#headers**: The `HTTP::Headers` of the response.
- **#version**: The HTTP version.
- **#parse**: (return value depends on MIME type) parse the body using a parser defined for the #mime_type.
- **#to_a**: A `Hash` of status code, response headers and body as a string.
- **#to_s**: Return response body as a string.

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

## Advanced Usage

### Sessions

As like [requests.Session()](http://docs.python-requests.org/en/master/user/advanced/#session-objects), Halite built-in session by default.

Let's persist some cookies across requests:

```crystal
client = Halite::Client.new
# Or
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
r = client.get("http://httpbin.org/cookies")
# => halite | 2017-12-13 17:40:53 | GET    | http://httpbin.org/cookies/set?private_token=6abaef100b77808ceb7fe26a3bcff1d0
# => halite | 2017-12-13 17:40:53 | 302    | http://httpbin.org/cookies/set?private_token=6abaef100b77808ceb7fe26a3bcff1d0 | text/html | <html> ...
# => halite | 2017-12-13 17:40:53 | GET    | http://httpbin.org/cookies
# => halite | 2017-12-13 17:40:55 | 200    | http://httpbin.org/cookies | application/json | {
# =>   "cookies": {
# =>     "private_token": "6abaef100b77808ceb7fe26a3bcff1d0"
# =>   }
# => }
```

All it support with [chainable methods](https://icyleaf.github.io/halite/Halite/Chainable.html) in the other examples list in [requests.Session](http://docs.python-requests.org/en/master/user/advanced/#session-objects).

### Logging

the Halite does not enable logging on each request and response too. You can enable per operation logging by configuring them through the chaining API.

#### Simple logging

```crystal
Halite.logger
      .get("http://httpbin.org/get", params: {name: "foobar"})

# => halite | 2017-12-13 16:41:32 | GET    | http://httpbin.org/get?name=foobar
# => halite | 2017-12-13 16:42:03 | 200    | http://httpbin.org/get?name=foobar | application/json | { ... }

Halite.logger
      .get("http://httpbin.org/image/png")

# => halite | 2017-12-13 16:41:32 | GET    | http://httpbin.org/image/png
# => halite | 2017-12-13 16:42:03 | 200    | http://httpbin.org/image/png | image/png | [binary file]
```

#### Logging request only

If you want logging request behavior only, throught pass `response` argument to `false`. And it not output the full body with binary type MIME types, please review it [here](https://github.com/icyleaf/halite/blob/master/src/halite/loggers/common_logger.cr#L79).

```crystal
Halite.logger(response: false)
      .get("http://httpbin.org/get", params: {name: "foobar"})

# => halite | 2017-12-13 16:41:32 | GET    | http://httpbin.org/get?name=foobar
```

#### Write to a log file

```crystal
Halite.logger(filename: "halite.log", response: false)
      .get("http://httpbin.org/get", params: {name: "foobar"})
```

#### Use the custom logger

Creating the custom logger by integration `Halite::Logger` abstract class.
here has two methods must be implement: `Halite::Logger.request` and `Halite::Logger.response`.

```crystal
class MyLogger < Halite::Logger
  def request(request)
    @logger.info ">> | %s | %s %s" % [request.verb, request.uri, request.body]
  end

  def response(response)
    @logger.info "<< | %s | %s %s" % [response.status_code, response.uri, response.mime_type]
  end
end

Halite.logger(MyLogger.new)
      .get("http://httpbin.org/get", params: {name: "foobar"})

# => halite | 2017-12-13 16:40:13 >> | GET | http://httpbin.org/get?name=foobar
# => halite | 2017-12-13 16:40:15 << | 200 | http://httpbin.org/get?name=foobar application/json
```

## Help and Discussion

You can browse the API documents:

https://icyleaf.github.io/halite/

You can browse the all chainable methods:

https://icyleaf.github.io/halite/Halite/Chainable.html

If you have found a bug, please create a issue here:

https://github.com/icyleaf/halite/issues/new

## Contributing

1. Fork it ( https://github.com/icyleaf/halite/fork )
2. Create your feature branch (git checkout -b my-new-feature)
3. Commit your changes (git commit -am 'Add some feature')
4. Push to the branch (git push origin my-new-feature)
5. Create a new Pull Request

## Contributors

- [icyleaf](https://github.com/icyleaf) - creator, maintainer
