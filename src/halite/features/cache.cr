require "json"
require "digest"
require "file_utils"

module Halite
  # Cache feature use for caching HTTP response to local storage to speed up in developing stage.
  #
  # It has the following options:
  #
  # - `path`: The path of cache, default is "cache/"
  # - `expires`: The expires time of cache, default is nerver expires.
  # - `debug`: The debug mode of cache, default is `true`
  #
  # With debug mode, cached response it always included some headers information:
  #
  # - `X-Cached-Key`: Cache key with verb, uri and body
  # - `X-Cached-At`:  Cache created time
  # - `X-Cached-Expires-At`: Cache expired time
  # - `X-Cached-By`: Always return "Halite"
  #
  # ```
  # Halite.use("cache").get "http://httpbin.org/anything"         # request a HTTP
  # r = Halite.use("cache").get "http://httpbin.org/anything"     # request from local storage
  # r.headers # => {..., "X-Cached-At" => "2018-08-30 10:41:14 UTC", "X-Cached-By" => "Halite", "X-Cached-Expires-At" => "2018-08-30 10:41:19 UTC", "X-Cached-Key" => "2bb155e6c8c47627da3d91834eb4249a"}}
  # ```
  class Cache < Feature
    DEFAULT_PATH = "cache/"

    @path : String
    @expires : Time::Span?
    @debug : Bool

    def initialize(**options)
      @path = options.fetch(:path, DEFAULT_PATH).as(String)
      @expires = options[:expires]?.as(Time::Span?)
      @debug = options.fetch(:debug, true).as(Bool)
    end

    def intercept(chain)
      response = cache(chain) do
        chain.perform
      end

      chain.return(response)
    end

    private def cache(chain, &block : -> Response)
      if response = find_cache(chain.request)
        return response
      end

      response = yield
      write_cache(chain.request, response)
      response
    end

    private def find_cache(request : Request) : Response?
      key = generate_cache_key(request)
      file = File.join(@path, key)

      if File.exists?(file) && !cache_expired?(file)
        cache = JSON.parse(File.open(file)).as_h
        status_code = cache["status_code"].as_i
        body = cache["body"].as_s
        headers = cache["headers"].as_h.each_with_object(HTTP::Headers.new) do |(key, value), obj|
          obj[key] = value.as_s
        end

        if @debug
          headers["X-Cached-Key"] = key
          headers["X-Cached-At"] = cache_created_time(file).to_s
          headers["X-Cached-Expires-At"] = @expires ? (cache_created_time(file) + @expires.not_nil!).to_s : "None"
          headers["X-Cached-By"] = "Halite"
        end

        return Response.new(request.uri, status_code, body, headers)
      end
    end

    private def cache_expired?(file)
      return false unless expires = @expires
      file_modified_time = cache_created_time(file)
      Time.now >= (file_modified_time + expires)
    end

    private def cache_created_time(file)
      File.info(file).modification_time
    end

    private def generate_cache_key(request : Request) : String
      Digest::MD5.hexdigest("#{request.verb}-#{request.uri}-#{request.body}")
    end

    private def write_cache(request, response)
      FileUtils.mkdir_p(@path) unless Dir.exists?(@path)

      key = generate_cache_key(request)
      File.open(File.join(@path, key), "w") do |f|
        f.puts({
          "status_code" => response.status_code,
          "headers" => response.headers.to_h,
          "body" => response.body
        }.to_json)
      end
    end

    Halite.register_feature "cache", self
  end
end
