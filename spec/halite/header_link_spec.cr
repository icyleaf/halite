require "../spec_helper"

private def parse_it(raw : String, uri : URI? = nil)
  Halite::HeaderLinkParser.parse(raw, uri)
end

describe Halite::HeaderLinkParser do
  it "should returns only url" do
    links = parse_it("http://example.net/bar")
    links.should be_a Hash(String, Halite::HeaderLink)
    links.not_nil!["http://example.net/bar"].rel.should eq "http://example.net/bar"
    links.not_nil!["http://example.net/bar"].target.should eq "http://example.net/bar"
    links.not_nil!["http://example.net/bar"].params.size.should eq 0
    links.not_nil!["http://example.net/bar"].to_s.should eq "http://example.net/bar"
  end

  it "should returns without 'rel' attribute" do
    links = parse_it("<http://example.net/foobar>;")
    links.should be_a Hash(String, Halite::HeaderLink)
    links.not_nil!["http://example.net/foobar"].rel.should eq "http://example.net/foobar"
    links.not_nil!["http://example.net/foobar"].target.should eq "http://example.net/foobar"

    links = parse_it(%Q{<http://example.net/foobar>; type="text/html"; })
    links.should be_a Hash(String, Halite::HeaderLink)
    links.not_nil!["http://example.net/foobar"].rel.should eq "http://example.net/foobar"
    links.not_nil!["http://example.net/foobar"].target.should eq "http://example.net/foobar"
    links.not_nil!["http://example.net/foobar"].params.size.should eq 1
    links.not_nil!["http://example.net/foobar"].params["type"].should eq "text/html"
  end

  it "should returns with relative path and none-given uri of response" do
    uri = URI.parse("http://sub.example.com/foo/bar")
    links = parse_it(%Q{</TheBook/chapter2>;rel="previous"}, uri)
    links.should be_a Hash(String, Halite::HeaderLink)
    links.not_nil!["previous"].rel.should eq "previous"

    target = uri.dup
    target.path = "/TheBook/chapter2"
    links.not_nil!["previous"].target.should eq target.to_s
  end

  it "should returns and keep the first value with multiple same attributes" do
    links = parse_it(%Q{<TheBook/chapter2>; rel="foo bar";title="Foo";rel="bar";title="Bar"})
    links.not_nil!.has_key?("foo bar").should be_true
    links.not_nil!.has_key?("bar").should be_false
    links.not_nil!["foo bar"].target.should eq "TheBook/chapter2"
    links.not_nil!["foo bar"].params["title"].should eq "Foo"
  end

  it "should return a list of links" do
    hash = parse_it(%Q{<https://api.github.com/user/repos?page=3&per_page=100>; rel="next"; title="Next Page", </>; rel="http://example.net/foo"})
    hash.should be_a Hash(String, Halite::HeaderLink)
    if links = hash
      links.has_key?("next").should be_true
      links["next"].rel.should eq "next"
      links["next"].target.should eq "https://api.github.com/user/repos?page=3&per_page=100"
      links["next"].params.size.should eq 1
      links["next"].params["title"].should eq "Next Page"
      links["next"].to_s.should eq "https://api.github.com/user/repos?page=3&per_page=100"

      links.has_key?("/").should be_false
      links["http://example.net/foo"].rel.should eq "http://example.net/foo"
      links["http://example.net/foo"].target.should eq "http://example.net/foo"
      links["http://example.net/foo"].params.size.should eq 0
      links["http://example.net/foo"].to_s.should eq "http://example.net/foo"
    end
  end
end
