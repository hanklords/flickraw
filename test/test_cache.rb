# -*- coding: utf-8 -*-

lib = File.dirname(__FILE__)
$:.unshift lib unless $:.include?(lib)

require 'test/unit'
require 'tempfile'
require 'yaml'
require 'benchmark'

class TestCache < Test::Unit::TestCase

  def test_read_and_write
    ::Flickr.class_variable_set :@@initialized, false if ::Flickr.class_variable_get :@@initialized

    file = Tempfile.new(['flickr-gem-test', '.yml'])
    path = file.path
    file.close
    file.unlink

    refute File.exist? path

    ::Flickr.cache = path

    no_cache_timer = Benchmark.realtime do
      ::Flickr.new
    end

    assert File.exist? path
    from_disk = YAML.load_file path
    assert_equal Array, from_disk.class
    assert_equal 222, from_disk.count
    assert from_disk.all? { |x| /\Aflickr(\.(?i:[a-z]+))+\z/ === x }

    cache_timer = Benchmark.realtime do
      ::Flickr.new
    end

    assert_operator no_cache_timer, :>, cache_timer
    assert_operator 10, :<, no_cache_timer / cache_timer

  ensure
    File.unlink path
  end
end
