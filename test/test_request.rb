# -*- coding: utf-8 -*-

lib = File.dirname(__FILE__)
$:.unshift lib unless $:.include?(lib)

require 'test/unit'
require 'helper'

class TestReqeust < Test::Unit::TestCase

  def test_flickr_api_is_accessible_via_methods
    # Reset FlickRaw (was initialized in test/helper.rb) so the request methods
    # are properly built
    $flickraw = nil
    FlickRaw::Request.instance_variable_set(:@flickr_objects, nil)

    FlickRaw::Flickr.build(['flickr.fully.legal'])

    assert_equal true, flickr.methods.include?(:fully)
    assert_equal true, flickr.fully.methods.include?(:legal)
  end

  def test_invalid_keys_are_skipped
    assert_nothing_raised {
      FlickRaw::Flickr.build ["flickr.hacked; end; raise 'Pwned'; def x"]
    }

    assert_equal false, flickr.methods.include?(:hacked)
  end

end

