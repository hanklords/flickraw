# -*- coding: utf-8 -*-

require 'test/unit'
require 'lib/flickraw'

class Basic < Test::Unit::TestCase
  def test_request
    flickr_objects = %w{activity auth blogs collections commons contacts
       favorites groups interestingness machinetags panda
       people photos photosets places prefs reflection tags
       test urls
    }
    assert_equal FlickRaw::Flickr.flickr_objects, flickr_objects
    flickr_objects.each {|o|
      assert_respond_to  flickr, o
      assert_kind_of FlickRaw::Request, eval("flickr." + o)
    }
  end
  
  def test_known
    known_methods = %w{
      flickr.activity.userComments
      flickr.activity.userPhotos
      flickr.auth.checkToken
      flickr.auth.getFrob
      flickr.auth.getFullToken
      flickr.auth.getToken
      flickr.blogs.getList
      flickr.blogs.getServices
      flickr.blogs.postPhoto
      flickr.collections.getInfo
      flickr.collections.getTree
      flickr.commons.getInstitutions
      flickr.contacts.getList
      flickr.contacts.getListRecentlyUploaded
      flickr.contacts.getPublicList
      flickr.favorites.add
      flickr.favorites.getList
      flickr.favorites.getPublicList
      flickr.favorites.remove
      flickr.groups.browse
      flickr.groups.getInfo
      flickr.groups.members.getList
      flickr.groups.pools.add
      flickr.groups.pools.getContext
      flickr.groups.pools.getGroups
      flickr.groups.pools.getPhotos
      flickr.groups.pools.remove
      flickr.groups.search
      flickr.interestingness.getList
      flickr.machinetags.getNamespaces
      flickr.machinetags.getPairs
      flickr.machinetags.getPredicates
      flickr.machinetags.getRecentValues
      flickr.machinetags.getValues
      flickr.panda.getList
      flickr.panda.getPhotos
      flickr.people.findByEmail
      flickr.people.findByUsername
      flickr.people.getInfo
      flickr.people.getPublicGroups
      flickr.people.getPublicPhotos
      flickr.people.getUploadStatus
      flickr.photos.addTags
      flickr.photos.comments.addComment
      flickr.photos.comments.deleteComment
      flickr.photos.comments.editComment
      flickr.photos.comments.getList
      flickr.photos.comments.getRecentForContacts
      flickr.photos.delete
      flickr.photos.geo.batchCorrectLocation
      flickr.photos.geo.correctLocation
      flickr.photos.geo.getLocation
      flickr.photos.geo.getPerms
      flickr.photos.geo.photosForLocation
      flickr.photos.geo.removeLocation
      flickr.photos.geo.setContext
      flickr.photos.geo.setLocation
      flickr.photos.geo.setPerms
      flickr.photos.getAllContexts
      flickr.photos.getContactsPhotos
      flickr.photos.getContactsPublicPhotos
      flickr.photos.getContext
      flickr.photos.getCounts
      flickr.photos.getExif
      flickr.photos.getFavorites
      flickr.photos.getInfo
      flickr.photos.getNotInSet
      flickr.photos.getPerms
      flickr.photos.getRecent
      flickr.photos.getSizes
      flickr.photos.getUntagged
      flickr.photos.getWithGeoData
      flickr.photos.getWithoutGeoData
      flickr.photos.licenses.getInfo
      flickr.photos.licenses.setLicense
      flickr.photos.notes.add
      flickr.photos.notes.delete
      flickr.photos.notes.edit
      flickr.photos.recentlyUpdated
      flickr.photos.removeTag
      flickr.photos.search
      flickr.photos.setContentType
      flickr.photos.setDates
      flickr.photos.setMeta
      flickr.photos.setPerms
      flickr.photos.setSafetyLevel
      flickr.photos.setTags
      flickr.photos.transform.rotate
      flickr.photos.upload.checkTickets
      flickr.photosets.addPhoto
      flickr.photosets.comments.addComment
      flickr.photosets.comments.deleteComment
      flickr.photosets.comments.editComment
      flickr.photosets.comments.getList
      flickr.photosets.create
      flickr.photosets.delete
      flickr.photosets.editMeta
      flickr.photosets.editPhotos
      flickr.photosets.getContext
      flickr.photosets.getInfo
      flickr.photosets.getList
      flickr.photosets.getPhotos
      flickr.photosets.orderSets
      flickr.photosets.removePhoto
      flickr.places.find
      flickr.places.findByLatLon
      flickr.places.getChildrenWithPhotosPublic
      flickr.places.getInfo
      flickr.places.getInfoByUrl
      flickr.places.getPlaceTypes
      flickr.places.getShapeHistory
      flickr.places.getTopPlacesList
      flickr.places.placesForBoundingBox
      flickr.places.placesForContacts
      flickr.places.placesForTags
      flickr.places.placesForUser
      flickr.places.resolvePlaceId
      flickr.places.resolvePlaceURL
      flickr.places.tagsForPlace
      flickr.prefs.getContentType
      flickr.prefs.getGeoPerms
      flickr.prefs.getHidden
      flickr.prefs.getPrivacy
      flickr.prefs.getSafetyLevel
      flickr.reflection.getMethodInfo
      flickr.reflection.getMethods
      flickr.tags.getClusterPhotos
      flickr.tags.getClusters
      flickr.tags.getHotList
      flickr.tags.getListPhoto
      flickr.tags.getListUser
      flickr.tags.getListUserPopular
      flickr.tags.getListUserRaw
      flickr.tags.getRelated
      flickr.test.echo
      flickr.test.login
      flickr.test.null
      flickr.urls.getGroup
      flickr.urls.getUserPhotos
      flickr.urls.getUserProfile
      flickr.urls.lookupGroup
      flickr.urls.lookupUser
    }
    found_methods = flickr.reflection.getMethods
    assert_instance_of FlickRaw::ResponseList, found_methods
    assert_equal known_methods, found_methods.to_a
  end
  
  def test_list
    list = flickr.photos.getRecent :per_page => '10'
    assert_instance_of FlickRaw::ResponseList, list
    assert_equal(list.size, 10)
  end

  def test_photo
    id = "3839885270"
    info = nil
    assert_nothing_raised(FlickRaw::FailedResponse) {
      info = flickr.photos.getInfo(:photo_id => id)
    }

     %w{id secret server farm license owner title description dates comments tags media}.each {|m|
      assert_respond_to info, m
      assert_not_nil info[m]
    }

    assert_equal info.id, id
    assert_equal "cat", info.title
    assert_equal "This is my cat", info.description
    assert_equal "ruby_flickraw", info.owner["username"]
    assert_equal "Flickraw", info.owner["realname"]
    assert_equal %w{cat pet}, info.tags.map {|t| t.to_s}.sort
    
    assert_equal "http://farm3.static.flickr.com/2485/3839885270_6fb8b54e06.jpg", FlickRaw.url(info)
    assert_equal "http://farm3.static.flickr.com/2485/3839885270_6fb8b54e06_m.jpg", FlickRaw.url_m(info)
    assert_equal "http://farm3.static.flickr.com/2485/3839885270_6fb8b54e06_s.jpg", FlickRaw.url_s(info)
    assert_equal "http://farm3.static.flickr.com/2485/3839885270_6fb8b54e06_t.jpg", FlickRaw.url_t(info)
    assert_equal "http://farm3.static.flickr.com/2485/3839885270_6fb8b54e06_b.jpg", FlickRaw.url_b(info)

    assert_equal "http://www.flickr.com/people/41650587@N02/", FlickRaw.url_profile(info)
    assert_equal "http://www.flickr.com/photos/41650587@N02/", FlickRaw.url_photostream(info)
    assert_equal "http://www.flickr.com/photos/41650587@N02/3839885270", FlickRaw.url_photopage(info)
    assert_equal "http://www.flickr.com/photos/41650587@N02/sets/", FlickRaw.url_photosets(info)
    assert_equal "http://flic.kr/p/6Rjq7s", FlickRaw.url_short(info)
  end

  def test_url_escape
    result_set = nil
    assert_nothing_raised {
      result_set = flickr.photos.search :text => "family vacation"
    }
    assert_operator result_set.total.to_i, :>=, 0

    # Unicode tests
    echo = nil
    utf8_text = "Hélène François, €uro"
    assert_nothing_raised {
      echo = flickr.test.echo :utf8_text => utf8_text
    }
    assert_equal echo.utf8_text, utf8_text
  end
end
