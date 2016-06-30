require 'json'
require 'flickraw/util'
require 'flickraw/error'
require 'flickraw/oauth'
require 'flickraw/request'
require 'flickraw/response'
require 'flickraw/api'

module FlickRaw
  VERSION='0.9.9'
  USER_AGENT = "FlickRaw/#{VERSION}"
  
  self.secure = true
  self.check_certificate = true
end

# Use this to access the flickr API easily. You can type directly the flickr requests as they are described on the flickr website.
#  require 'flickraw'
#
#  recent_photos = flickr.photos.getRecent
#  puts recent_photos[0].title
def flickr; $flickraw ||= FlickRaw::Flickr.new end
