# Halite

![Status](https://img.shields.io/badge/status-WIP-yellow.svg)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](https://github.com/icyleaf/halite/blob/master/LICENSE)
[![Dependency Status](https://shards.rocks/badge/github/icyleaf/halite/status.svg)](https://shards.rocks/github/icyleaf/halite)
[![Build Status](https://img.shields.io/circleci/project/github/icyleaf/halite/master.svg?style=flat)](https://circleci.com/gh/icyleaf/halite)

Yet another simple HTTP and REST client writes with Crystal. Inspired from the Ruby's [HTTP](https://github.com/httprb/http)/[RESTClient](https://github.com/rest-client/rest-client) gem.

Build in crystal version >= `v0.23.1`, Docs Generated in latest commit.

## Table of Contents

- [Installation](#installation)
- [Usage](#usage)
  - [Making Requests](#making-requests)
  - [Passing Parameters](#passing-parameters)
  - [Passing advanced options](#passing-advanced-options)
    - [Headers](#headers)
    - [Auth](#auth)
    - [Cookies](#cookies)
    - [Sessions](#sessions)
    - [Redirects](#redirects)
    - [Timeout](#timeout)
  - [Response Handling](#response-handling)
    - [Error Handling](#error-handling)
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
Halite.get("http://httpbin.org/get", params: {
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

Many other HTTP methods are avaiabled as well:

- `get`
- `head`
- `patch`
- `post`
- `put`
- `delete`

```crystal
Halite.get("http://httpbin.org/get", params: { "firstname" => "Olen", "lastname" => "Rosenbaum" })

Halite.head("http://httpbin.org/anything", params: { "firstname" => "Olen", "lastname" => "Rosenbaum" })

Halite.post("http://httpbin.org/post", form: { "firstname" => "Olen", "lastname" => "Rosenbaum" })

Halite.put("http://httpbin.org/put", json: { "firstname" => "Olen", "lastname" => "Rosenbaum" })

Halite.patch("http://httpbin.org/anything", json: { "firstname" => "Olen", "lastname" => "Rosenbaum" })

Haltie.delete("http://httpbin.org/delete", params: { "user_id" => 234234 })
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
Halte.headers({ "private_token" => "T0k3n" }).get("http://httpbin.org/get")

# Or
Halte.headers({ private_token: "T0k3n" }).get("http://httpbin.org/get")
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

#### Sessions

As like [requests.Session](http://docs.python-requests.org/en/master/user/advanced/#session-objects), Halite built-in session by default.

Let's persist some cookies across requests:

```crystal
client = Halite::Client.new

client.get("http://httpbin.org/cookies/set?private_token=6abaef100b77808ceb7fe26a3bcff1d0")
r = client.get("http://httpbin.org/cookies")

pp r.body
```

All it support with [chainable methods](https://icyleaf.github.io/halite/Halite/Chainable.html) in the other examples list in [requests.Session](http://docs.python-requests.org/en/master/user/advanced/#session-objects).

#### Redirects

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
- **#to_a**: A `Hash` of status code, response headers and body as a string.
- **#to_s**: Return response body as a string.

#### Error Handling

- For any status code, a `Halite::Response` will be returned
- If request timeout, a `Halite::TimeoutError` will be raised.

## Help and Discussion

You can browese the API documents:

https://icyleaf.github.io/halite/

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
