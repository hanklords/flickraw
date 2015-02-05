require 'flickraw'
require 'sinatra'

FlickRaw.api_key = API_KEY
FlickRaw.shared_secret = SHARED_SECRET
use Rack::Session::Pool

get '/authenticate' do
  token = flickr.get_request_token(:oauth_callback => to('check'))
  session[:token] = token
  redirect flickr.get_authorize_url(token['oauth_token'], :perms => 'delete')
end

get '/check' do
  token = session.delete :token
  session[:auth_flickr] = @auth_flickr = FlickRaw::Flickr.new
  @auth_flickr.get_access_token(token['oauth_token'], token['oauth_token_secret'], params['oauth_verifier'])

  redirect to('/authenticated')
end

get '/authenticated' do
  @auth_flickr = session[:auth_flickr]

  login = @auth_flickr.test.login
  %{
You are now authenticated as <em>#{login.username}</em>
with token <strong>#{@auth_flickr.access_token}</strong> and secret <strong>#{@auth_flickr.access_secret}</strong>.
  }
end

