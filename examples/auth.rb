require 'flickraw'

# This is how to authenticate on flickr website.
# You need an API key for that, see http://www.flickr.com/services/api/keys/
API_KEY=''
SHARED_SECRET=''

FlickRaw.api_key=API_KEY
FlickRaw.shared_secret=SHARED_SECRET

token = flickr.get_request_token
auth_url = flickr.get_authorize_url(token['oauth_token'], :perms => 'delete')

puts "Open this url in your process to complete the authication process : #{auth_url}"
puts "Copy here the number given when you complete the process."
verify = gets.strip

begin
  flickr.get_access_token(token['oauth_token'], token['oauth_token_secret'], verify)
  login = flickr.test.login
  puts "You are now authenticated as #{login.username} with token #{flickr.access_token} and secret #{flickr.access_secret}"
rescue FlickRaw::FailedResponse => e
  puts "Authentication failed : #{e.msg}"
end
