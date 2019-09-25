require "json"
require "digest"
require "file_utils"

module Halite
  # Cache feature use for caching HTTP response to local storage to speed up in developing stage.
  #
  # It has the following options:
  #
  # - `file`: Load cache from file. it conflict with `path` and `expires`.
  # - `path`: The path of cache, default is "/tmp/halite/cache/"
  # - `expires`: The expires time of cache, default is never expires.
  # - `debug`: The debug mode of cache, default is `true`
  #
  # With debug mode, cached response it always included some headers information:
  #
  # - `X-Halite-Cached-From`: Cache source (cache or file)
  # - `X-Halite-Cached-Key`: Cache key with verb, uri and body (return with cache, not `file` passed)
  # - `X-Halite-Cached-At`:  Cache created time
  # - `X-Halite-Cached-Expires-At`: Cache expired time (return with cache, not `file` passed)
  #
  # ```
  # Halite.use("cache").get "http://httpbin.org/anything"     # request a HTTP
  # r = Halite.use("cache").get "http://httpbin.org/anything" # request from local storage
  # r.headers                                                 # => {..., "X-Halite-Cached-At" => "2018-08-30 10:41:14 UTC", "X-Halite-Cached-By" => "Halite", "X-Halite-Cached-Expires-At" => "2018-08-30 10:41:19 UTC", "X-Halite-Cached-Key" => "2bb155e6c8c47627da3d91834eb4249a"}}
  # ```
  class Cache < Feature
    DEFAULT_PATH = "/tmp/halite/cache/"

    getter file : String?
    getter path : String
    getter expires : Time::Span?
    getter debug : Bool

    # return a new Cache instance
    #
    # Accepts argument:
    #
    # - **debug**: `Bool`
    # - **path**: `String`
    # - **expires**: `(Int32 | Time::Span)?`
    def initialize(**options)
      @debug = options.fetch(:debug, true).as(Bool)
      if file = options[:file]?
        @file = file
        @path = DEFAULT_PATH
        @expires = nil
      else
        @file = nil
        @path = options.fetch(:path, DEFAULT_PATH).as(String)
        @expires = case expires = options[:expires]?
                   when Time::Span
                     expires.as(Time::Span)
                   when Int32
                     Time::Span.new(seconds: expires.as(Int32), nanoseconds: 0)
                   when Nil
                     nil
                   else
                     raise "Only accept Int32 and Time::Span type."
                   end
      end
    end

    def intercept(chain)
      response = cache(chain) do
        chain.perform
      end

      chain.return(response)
    end

    private def cache(chain, &block : -> Halite::Response)
      if response = find_cache(chain.request)
        return response
      end

      response = yield
      write_cache(chain.request, response)
      response
    end

    private def find_cache(request : Halite::Request) : Halite::Response?
      if file = @file
        build_response(request, file)
      elsif response = build_response(request)
        response
      end
    end

    private def find_file(file) : Halite::Response
      raise Error.new("Not find cache file: #{file}") if File.file?(file)
      build_response(file)
    end

    private def build_response(request : Halite::Request, file : String? = nil) : Halite::Response?
      status_code = 200
      headers = HTTP::Headers.new
      cache_from = "file"

      unless file
        # Cache in path
        key = generate_cache_key(request)
        path = File.join(@path, key)

        return unless Dir.exists?(path)

        cache_from = "cache"
        cache_file = File.join(path, "#{key}.cache")
        if File.file?(cache_file) && !cache_expired?(cache_file)
          file = cache_file

          if metadata = find_metadata(path)
            status_code = metadata["status_code"].as_i
            metadata["headers"].as_h.each do |name, value|
              headers[name] = value.as_s
            end
          end

          if @debug
            headers["X-Halite-Cached-Key"] = key
            headers["X-Halite-Cached-Expires-At"] = @expires ? (cache_created_time(file) + @expires.not_nil!).to_s : "None"
          end
        end
      end

      return unless file

      if @debug
        headers["X-Halite-Cached-From"] = cache_from
        headers["X-Halite-Cached-At"] = cache_created_time(file).to_s
      end

      body = File.read_lines(file).join("\n")
      Response.new(request.uri, status_code, body, headers)
    end

    private def find_metadata(path)
      file = File.join(path, "metadata.json")
      if File.exists?(file)
        JSON.parse(File.open(file)).as_h
      end
    end

    private def cache_expired?(file)
      return false unless expires = @expires
      file_modified_time = cache_created_time(file)
      Time.utc >= (file_modified_time + expires)
    end

    private def cache_created_time(file)
      File.info(file).modification_time
    end

    private def generate_cache_key(request) : String
      Digest::MD5.hexdigest("#{request.verb}-#{request.uri}-#{request.body}")
    end

    private def write_cache(request, response)
      key = generate_cache_key(request)
      path = File.join(@path, key)
      FileUtils.mkdir_p(path) unless Dir.exists?(path)

      write_metadata(path, response)
      write_body(path, key, response)
    end

    private def write_metadata(path, response)
      File.open(File.join(path, "metadata.json"), "w") do |f|
        f.puts({
          "status_code" => response.status_code,
          "headers"     => response.headers.to_flat_h,
        }.to_json)
      end
    end

    private def write_body(path, key, response)
      File.open(File.join(path, "#{key}.cache"), "w") do |f|
        f.puts response.body
      end
    end

    Halite.register_feature "cache", self
  end
end
