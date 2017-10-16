require 'flickraw'
require 'URI'
require 'digest/md5'

# search for pictures taken within 60 miles of new brunswick, between 1890-1920

# FlickRaw.api_key="..."
# FlickRaw.shared_secret="..."

new_b = flickr.places.find :query => "new brunswick"
latitude = new_b[0]['latitude'].to_f
longitude = new_b[0]['longitude'].to_f

# within 60 miles of new brunswick, let's use a bbox
radius = 1
args = {}
args[:bbox] = "#{longitude - radius},#{latitude - radius},#{longitude + radius},#{latitude + radius}"

# requires a limiting factor, so let's give it one
args[:min_taken_date] = '1890-01-01 00:00:00'
args[:max_taken_date] = '1920-01-01 00:00:00'
args[:accuracy] = 1 # the default is street only granularity [16], which most images aren't...
discovered_pictures = flickr.photos.search args
discovered_pictures.each{|p| url = FlickRaw.url p; puts url}


# Example needing api_sig (Searching for safe_search=3)
# Assumes user has been authenticated per other examples

safe_search_args = {}
safe_search_args[:auth_token] = token['oauth_token']
safe_search_args[:api_key] = ENV['FLICKR_API_KEY']
safe_search_args[:method] = 'flickr.photos.search'
safe_search_args[:safe_search] = 3  

# Base URL is HTTP Verb + Endpoint URL + all params in alphabetical order
# We then URL encode Base URL and make an MD5 Digest from encoded URL

base_url = 'POSThttps://api.flickr.com/services/rest/?auth_token=<YOUR TOKEN>&api_key=<YOU KEY>&method=flickr.photos.search&safe_search=3'
encoded_url = URI.encode_www_form_component(base_url)

safe_search_args[:api_sig] = Digest::MD5.hexdigest(encoded_url)

# Finally, we make the API Call
unsafe_photos = flickr.photos.search(args)