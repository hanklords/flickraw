# -*- coding: utf-8 -*-

lib = File.dirname(__FILE__)
$:.unshift lib unless $:.include?(lib)

require 'test/unit'

class TestRequest < Test::Unit::TestCase

  def setup
    @flickr = ::Flickr.new
  end

  def test_flickr_api_is_accessible_via_methods
    Flickr.new.send :build_classes, ['flickr.fully.legal']

    assert_equal true, @flickr.methods.include?(:fully)
    assert_equal true, @flickr.fully.methods.include?(:legal)
  end

  def test_invalid_endpoint_definition
    e = assert_raises(RuntimeError) do
      Flickr.new.send :build_classes, ['not_flickr.something.method']
    end
    assert_equal "Invalid namespace", e.message
  end

  def test_invalid_keys_are_skipped
    assert_nothing_raised {
      Flickr.new.send :build_classes, ["flickr.hacked; end; raise 'Pwned'; def x"]
    }

    assert_equal false, @flickr.methods.include?(:hacked)
  end

end
