require 'flickraw'

# This is how to upload photos on flickr.
# You need to be authentified to do that.

API_KEY=''
SHARED_SECRET=''
ACCESS_TOKEN=''
ACCESS_SECRET=''
PHOTO_PATH='photo.jpg'

FlickRaw.api_key = API_KEY
FlickRaw.shared_secret = SHARED_SECRET
flickr.access_token = ACCESS_TOKEN
flickr.access_secret = ACCESS_SECRET

flickr.upload_photo PHOTO_PATH, :title => 'Title', :description => 'This is the description'
