require "../../spec_helper"

private struct CacheStruct
  getter metadata, body, chain

  def initialize(@body : String, @chain : Halite::Feature::Chain, @metadata : Hash(String, JSON::Any)? = nil)
  end
end

private def cache_spec(cache, request, response, use_cache = false, wait_time : (Int32 | Time::Span)? = nil)
  FileUtils.rm_rf(cache.path)

  _chain = Halite::Feature::Chain.new(request, nil, Halite::Options.new) do
    response
  end

  if file = cache.file
    chain = cache.intercept(_chain)
    body = File.read_lines(file).join("\n")
    yield CacheStruct.new(body, chain)
  else
    key = Digest::MD5.hexdigest("#{request.verb}-#{request.uri}-#{request.body}")
    path = File.join(cache.path, key)
    metadata_file = File.join(path, "metadata.json")
    body_file = File.join(path, "#{key}.cache")

    cache.intercept(_chain) if use_cache

    if seconds = wait_time
      sleep seconds
    end

    chain = cache.intercept(_chain)

    Dir.exists?(path).should be_true
    File.file?(metadata_file).should be_true
    File.file?(body_file).should be_true

    metadata = JSON.parse(File.open(metadata_file)).as_h
    body = File.read_lines(body_file).join("\n")

    yield CacheStruct.new(body, chain, metadata)

    FileUtils.rm_rf(cache.path)
  end
end

describe Halite::Cache do
  it "should register a format" do
    Halite.has_feature?("cache").should be_true
    Halite.feature("cache").should eq(Halite::Cache)
  end

  describe "getters" do
    it "should default value" do
      feature = Halite::Cache.new
      feature.path.should eq(Halite::Cache::DEFAULT_PATH)
      feature.expires.should be_nil
      feature.debug.should be_true
    end

    it "should return setter value" do
      feature = Halite::Cache.new(path: "/tmp/cache", expires: 1.day, debug: false)
      feature.file.should be_nil
      feature.path.should eq("/tmp/cache")
      feature.expires.should eq(1.day)
      feature.debug.should be_false

      # expires accept Int32/Time::Span but return Time::Span
      feature = Halite::Cache.new(expires: 60)
      feature.file.should be_nil
      feature.path.should eq(Halite::Cache::DEFAULT_PATH)
      feature.expires.should eq(1.minutes)
      feature.debug.should be_true
    end
  end

  describe "intercept" do
    it "should cache to local storage" do
      body = {name: "foo"}.to_json
      request = Halite::Request.new("get", SERVER.api("/anything?q=halite1#result"), HTTP::Headers{"Accept" => "application/json"})
      response = Halite::Response.new(request.uri, 200, body, HTTP::Headers{"Content-Type" => "application/json", "Content-Length" => body.size.to_s})
      feature = Halite::Cache.new
      feature.file.should be_nil
      feature.path.should eq(Halite::Cache::DEFAULT_PATH)
      feature.expires.should be_nil
      feature.debug.should be_true

      # First return response on HTTP
      cache_spec(feature, request, response, use_cache: false) do |result|
        result.metadata.not_nil!["status_code"].should eq(200)
        result.metadata.not_nil!["headers"].as_h["Content-Type"].should eq("application/json")
        result.metadata.not_nil!["headers"].as_h["Content-Length"].should eq(response.body.size.to_s)
        result.body.should eq(response.body)
        result.chain.result.should eq(Halite::Feature::Chain::Result::Return)
        result.chain.response.should eq(response)
      end

      # Second return response on Cache
      cache_spec(feature, request, response, use_cache: true) do |result|
        result.metadata.not_nil!["status_code"].should eq(200)
        result.metadata.not_nil!["headers"].as_h["Content-Type"].should eq("application/json")
        result.metadata.not_nil!["headers"].as_h["Content-Length"].should eq(response.body.size.to_s)
        result.body.should eq(response.body)
        result.chain.result.should eq(Halite::Feature::Chain::Result::Return)

        result.chain.response.should_not be_nil
        result.chain.response.not_nil!.headers["X-Halite-Cached-From"].should eq("cache")
        result.chain.response.not_nil!.headers["X-Halite-Cached-Key"].should_not eq("")
        result.chain.response.not_nil!.headers["X-Halite-Cached-At"].should_not eq("")
        result.chain.response.not_nil!.headers["X-Halite-Cached-Expires-At"].should eq("None")
      end
    end

    it "should cache without debug mode" do
      body = {name: "foo1"}.to_json
      request = Halite::Request.new("get", SERVER.api("/anything?q=halite2#result"), HTTP::Headers{"Accept" => "application/json"})
      response = Halite::Response.new(request.uri, 200, body, HTTP::Headers{"Content-Type" => "application/json", "Content-Length" => body.size.to_s})
      feature = Halite::Cache.new(debug: false)
      feature.file.should be_nil
      feature.path.should eq(Halite::Cache::DEFAULT_PATH)
      feature.expires.should be_nil
      feature.debug.should be_false

      cache_spec(feature, request, response, use_cache: true) do |result|
        result.metadata.not_nil!["status_code"].should eq(200)
        result.metadata.not_nil!["headers"].as_h["Content-Type"].should eq("application/json")
        result.metadata.not_nil!["headers"].as_h["Content-Length"].should eq(response.body.size.to_s)
        result.body.should eq(response.body)
        result.chain.result.should eq(Halite::Feature::Chain::Result::Return)

        result.chain.response.should_not be_nil
        result.chain.response.not_nil!.headers.has_key?("X-Halite-Cached-From").should be_false
        result.chain.response.not_nil!.headers.has_key?("X-Halite-Cached-Key").should be_false
        result.chain.response.not_nil!.headers.has_key?("X-Halite-Cached-At").should be_false
      end
    end

    it "should return no cache if expired" do
      body = {name: "foo2"}.to_json
      request = Halite::Request.new("get", SERVER.api("/anything?q=halite3#result"), HTTP::Headers{"Accept" => "application/json"})
      response = Halite::Response.new(request.uri, 200, body, HTTP::Headers{"Content-Type" => "application/json", "Content-Length" => body.size.to_s})
      feature = Halite::Cache.new(expires: 1.milliseconds)
      feature.file.should be_nil
      feature.path.should eq(Halite::Cache::DEFAULT_PATH)
      feature.expires.should eq(1.milliseconds)
      feature.debug.should be_true

      cache_spec(feature, request, response, use_cache: true, wait_time: 500.milliseconds) do |result|
        result.metadata.not_nil!["status_code"].should eq(200)
        result.metadata.not_nil!["headers"].as_h["Content-Type"].should eq("application/json")
        result.metadata.not_nil!["headers"].as_h["Content-Length"].should eq(response.body.size.to_s)
        result.body.should eq(response.body)
        result.chain.result.should eq(Halite::Feature::Chain::Result::Return)

        result.chain.response.should_not be_nil
        result.chain.response.not_nil!.headers.has_key?("X-Halite-Cached-From").should be_false
        result.chain.response.not_nil!.headers.has_key?("X-Halite-Cached-Key").should be_false
        result.chain.response.not_nil!.headers.has_key?("X-Halite-Cached-At").should be_false
        result.chain.response.not_nil!.headers.has_key?("X-Halite-Cached-Expires-At").should be_false
      end
    end

    it "should load cache from file" do
      file = fixture_path("cache_file.json")
      body = load_fixture("cache_file.json")
      request = Halite::Request.new("get", SERVER.api("/anything?q=halite4#result"), HTTP::Headers{"Accept" => "application/json"})
      response = Halite::Response.new(request.uri, 200, body, HTTP::Headers{"Content-Type" => "application/json", "Content-Length" => body.size.to_s})
      feature = Halite::Cache.new(file: file)
      feature.file.should eq(file)
      feature.path.should eq(Halite::Cache::DEFAULT_PATH)
      feature.expires.should be_nil
      feature.debug.should be_true

      cache_spec(feature, request, response, file) do |result|
        result.metadata.should be_nil
        result.body.should eq(response.body)
        result.chain.result.should eq(Halite::Feature::Chain::Result::Return)

        result.chain.response.should_not be_nil
        result.chain.response.not_nil!.headers["X-Halite-Cached-From"].should eq("file")
        result.chain.response.not_nil!.headers.has_key?("X-Halite-Cached-Key").should be_false
        result.chain.response.not_nil!.headers["X-Halite-Cached-At"].should_not eq("")
        result.chain.response.not_nil!.headers.has_key?("X-Halite-Cached-Expires-At").should be_false
      end
    end
  end
end
