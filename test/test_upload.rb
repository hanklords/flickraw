# -*- coding: utf-8 -*-

lib = File.dirname(__FILE__)
$:.unshift lib unless $:.include?(lib)

require 'test/unit'

class Upload < Test::Unit::TestCase

  def setup
    @flickr = ::Flickr.new
  end

  def test_upload
    u = info = nil
    path = File.dirname(__FILE__) + '/image testée.jpg'
    title = "Titre de l'image testée"
    description = "Ceci est la description de l'image testée"

    assert_nothing_raised do
      u = @flickr.upload_photo path,
        :title => title,
        :description => description
    end

    assert_nothing_raised do
      info = @flickr.photos.getInfo :photo_id => u.to_s
    end

    assert_equal title, info.title
    assert_equal description, info.description

    assert_nothing_raised {@flickr.photos.delete :photo_id => u.to_s}
  end

end
