# -*- coding: utf-8 -*-

lib = File.expand_path('../../lib/', __FILE__)
$:.unshift lib unless $:.include?(lib)

require 'test/unit'
require 'flickraw'

class TestReqeust < Test::Unit::TestCase
  def test_flickr_api_is_accessible_via_methods
    FlickRaw::Flickr.build(['flickr.fully.legal'])

    flickr = FlickRaw::Flickr.new

    assert_equal true, flickr.methods.include?(:fully)
    assert_equal true, flickr.fully.methods.include?(:legal)
  end

  def test_invalid_keys_are_skipped
    assert_nothing_raised {
      FlickRaw::Flickr.build ["flickr.hacked; end; raise 'Pwned'; def x"]
    }

    flickr = FlickRaw::Flickr.new

    assert_equal false, flickr.methods.include?(:hacked)
  end

end
