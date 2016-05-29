module FlickRaw

  # Use this to access the flickr API easily. You can type directly the flickr requests as they are described on the flickr website.
  #  require 'flickraw'
  #  include Flickraw::Helper
  #
  #  recent_photos = flickr.photos.getRecent
  #  puts recent_photos[0].title
  module Helper
    def flickr
      @flickraw ||= FlickRaw::Flickr.new
    end
  end

end
