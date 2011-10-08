# -*- coding: utf-8 -*-

lib = File.dirname(__FILE__)
$:.unshift lib unless $:.include?(lib)

require 'test/unit'
require 'helper'

class Upload < Test::Unit::TestCase
  def test_upload
    path = File.dirname(__FILE__) + '/image testée.jpg'
    u = info = nil
    title = "Titre de l'image testée"
    description = "Ceci est la description de l'image testée"
    assert_nothing_raised {
      u = flickr.upload_photo path,
        :title => title,
        :description => description
    }

    assert_nothing_raised {
      info = flickr.photos.getInfo :photo_id => u.to_s
    }

    assert_equal title, info.title
    assert_equal description, info.description

    assert_nothing_raised {flickr.photos.delete :photo_id => u.to_s}
  end
end
