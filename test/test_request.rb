# -*- coding: utf-8 -*-

lib = File.expand_path('../../lib/', __FILE__)
$:.unshift lib unless $:.include?(lib)

require 'test/unit'
require 'flickraw'

class TestReqeust < Test::Unit::TestCase

  def setup
    @flickr = FlickRaw::Flickr.new

    @flickr.access_token = ENV['FLICKRAW_ACCESS_TOKEN']
    @flickr.access_secret = ENV['FLICKRAW_ACCESS_SECRET']
  end

  def test_flickr_api_is_accessible_via_methods
    FlickRaw::Request.instance_variable_set(:@flickr_objects, nil)

    FlickRaw::Flickr.build(['flickr.fully.legal'])

    assert_equal true, @flickr.methods.include?(:fully)
    assert_equal true, @flickr.fully.methods.include?(:legal)
  end

  def test_invalid_keys_are_skipped
    assert_nothing_raised {
      FlickRaw::Flickr.build ["flickr.hacked; end; raise 'Pwned'; def x"]
    }

    assert_equal false, @flickr.methods.include?(:hacked)
  end

end
