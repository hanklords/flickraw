lib = File.expand_path('../../lib/', __FILE__)
$:.unshift lib unless $:.include?(lib)

require 'flickraw'

FlickRaw.api_key = ENV['FLICKRAW_API_KEY']
FlickRaw.shared_secret = ENV['FLICKRAW_SHARED_SECRET']
#FlickRaw.secure = false

flickr.access_token = ENV['FLICKRAW_ACCESS_TOKEN']
flickr.access_secret = ENV['FLICKRAW_ACCESS_SECRET']
