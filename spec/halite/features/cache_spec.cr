require "../../spec_helper"

describe Halite::Cache do
  it "should register a format" do
    Halite.has_feature?("cache").should be_true
    Halite.feature("cache").should eq(Halite::Cache)
  end

  describe "intercept" do
    it "should cache to local storage" do
      body = {name: "foo"}.to_json
      request = Halite::Request.new("get", SERVER.api("/anything?q=halite#result"), HTTP::Headers{"Accept" => "application/json"})
      response = Halite::Response.new(request.uri, 200, body, HTTP::Headers{"Content-Type" => "application/json", "Content-Length" => body.size.to_s})
      chain = Halite::Feature::Chain.new(request, nil, Halite::Options.new) do
        response
      end

      feature = Halite::Cache.new
      feature.path.should eq(Halite::Cache::DEFAULT_PATH)
      feature.expires.should be_nil
      feature.debug.should be_true

      feature.intercept(chain)

      cache_key = Digest::MD5.hexdigest("#{request.verb}-#{request.uri}-#{request.body}")
      cache_path = File.join(feature.path, cache_key)

      metadata_file = File.join(cache_path, "metadata.json")
      body_file = File.join(cache_path, "#{cache_key}.cache")

      Dir.exists?(cache_path).should be_true
      File.file?(metadata_file).should be_true
      File.file?(body_file).should be_true

      metadata = JSON.parse(File.open(metadata_file)).as_h
      metadata["status_code"].should eq(200)
      metadata["headers"].as_h["Content-Type"].should eq("application/json")
      metadata["headers"].as_h["Content-Length"].should eq(body.size.to_s)

      cache_body = File.read_lines(body_file).join("\n")
      cache_body.should eq(body)

      # Clean up
      FileUtils.rm_rf feature.path
    end
  end
end
