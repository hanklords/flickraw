# -*- coding: utf-8 -*-

lib = File.dirname(__FILE__)
$:.unshift lib unless $:.include?(lib)

require 'test/unit'
require 'helper'

class TestResponse < Test::Unit::TestCase

  def test_response_keys_are_turned_into_methods
    subject = FlickRaw::Response.new({ 'le_gal' => 'ok', }, nil)

    assert_equal true, subject.methods.include?(:le_gal)
    assert_equal 'ok', subject.le_gal
  end

  def test_invalid_keys_are_skipped
    response_hash = {
      'illegal; end; raise "Pwned"; def x' => 'skipped'
    }

    assert_nothing_raised {
      FlickRaw::Response.new(response_hash, nil)
    }

    subject = FlickRaw::Response.new(response_hash, nil)
    assert_equal false, subject.methods.include?(:illegal)
  end

end
