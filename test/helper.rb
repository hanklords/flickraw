lib = File.expand_path('../../lib/', __FILE__)
$:.unshift lib unless $:.include?(lib)

require 'flickraw'

flickr = FlickRaw::Flickr.new
flickr.access_token = ENV['FLICKRAW_ACCESS_TOKEN']
flickr.access_secret = ENV['FLICKRAW_ACCESS_SECRET']
