require 'flickraw'
require 'sinatra'

FlickRaw.api_key = API_KEY
FlickRaw.shared_secret = SHARED_SECRET
enable :sessions

get '/authenticate' do
  token = flickr.get_request_token(:oauth_callback => to('authenticated'))
  session[:token] = token
  redirect flickr.get_authorize_url(token['oauth_token'], :perms => 'delete')
end

get '/authenticated' do
  token = session[:token]
  flickr.get_access_token(token['oauth_token'], token['oauth_token_secret'], params['oauth_verifier'])
  login = flickr.test.login
  %{
You are now authenticated as <b>#{login.username}</b>
with token <b>#{flickr.access_token}</b> and secret <b>#{flickr.access_secret}</b>.
}
end
