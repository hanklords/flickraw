module FlickRaw

  # Root class of the flickr api hierarchy.
  class Flickr < Request
    # Authenticated access token
    attr_accessor :access_token

    # Authenticated access token secret
    attr_accessor :access_secret

    def self.build(methods); methods.each { |m| build_request m } end

    def initialize(api_key = ENV['FLICKRAW_API_KEY'], shared_secret = ENV['FLICKRAW_SHARED_SECRET'])

      raise FlickrAppNotConfigured.new("No API key defined!") if api_key.nil?
      raise FlickrAppNotConfigured.new("No shared secret defined!") if shared_secret.nil?

      @oauth_consumer = OAuthClient.new(api_key, shared_secret)
      @oauth_consumer.proxy = FlickRaw.proxy
      @oauth_consumer.check_certificate = FlickRaw.check_certificate
      @oauth_consumer.ca_file = FlickRaw.ca_file
      @oauth_consumer.ca_path = FlickRaw.ca_path
      @oauth_consumer.user_agent = USER_AGENT
      @access_token = @access_secret = nil

      Flickr.build(call('flickr.reflection.getMethods')) if Flickr.flickr_objects.empty?
      super self
    end

    # This is the central method. It does the actual request to the flickr server.
    #
    # Raises FailedResponse if the response status is _failed_.
    def call(req, args={}, &block)
      oauth_args = args.delete(:oauth) || {}
      http_response = @oauth_consumer.post_form(REST_PATH, @access_secret, {:oauth_token => @access_token}.merge(oauth_args), build_args(args, req))
      process_response(req, http_response.body)
    end

    # Get an oauth request token.
    #
    #    token = flickr.get_request_token(:oauth_callback => "http://example.com")
    def get_request_token(args = {})
      @oauth_consumer.request_token(FLICKR_OAUTH_REQUEST_TOKEN, args)
    end

    # Get the oauth authorize url.
    #
    #  auth_url = flickr.get_authorize_url(token['oauth_token'], :perms => 'delete')
    def get_authorize_url(token, args = {})
      @oauth_consumer.authorize_url(FLICKR_OAUTH_AUTHORIZE, args.merge(:oauth_token => token))
    end

    # Get an oauth access token.
    #
    #  flickr.get_access_token(token['oauth_token'], token['oauth_token_secret'], oauth_verifier)
    def get_access_token(token, secret, verify)
      access_token = @oauth_consumer.access_token(FLICKR_OAUTH_ACCESS_TOKEN, secret, :oauth_token => token, :oauth_verifier => verify)
      @access_token, @access_secret = access_token['oauth_token'], access_token['oauth_token_secret']
      access_token
    end

    # Use this to upload the photo in _file_.
    #
    #  flickr.upload_photo '/path/to/the/photo', :title => 'Title', :description => 'This is the description'
    #
    # See http://www.flickr.com/services/api/upload.api.html for more information on the arguments.
    def upload_photo(file, args={})
      upload_flickr(UPLOAD_PATH, file, args)
    end

    # Use this to replace the photo with :photo_id with the photo in _file_.
    #
    #  flickr.replace_photo '/path/to/the/photo', :photo_id => id
    #
    # See http://www.flickr.com/services/api/replace.api.html for more information on the arguments.
    def replace_photo(file, args={})
      upload_flickr(REPLACE_PATH, file, args)
    end

    private
    def build_args(args={}, method = nil)
      args['method'] = method if method
      args.merge('format' => 'json', 'nojsoncallback' => '1')
    end

    def process_response(req, response)
      if response =~ /^<\?xml / # upload_photo returns xml data whatever we ask
        if response[/stat="(\w+)"/, 1] == 'fail'
          msg = response[/msg="([^"]+)"/, 1]
          code = response[/code="([^"]+)"/, 1]
          raise FailedResponse.new(msg, code, req)
        end

        type = response[/<(\w+)/, 1]
        h = {
          'secret' => response[/secret="([^"]+)"/, 1],
          'originalsecret' => response[/originalsecret="([^"]+)"/, 1],
          '_content' => response[/>([^<]+)<\//, 1]
        }.delete_if { |k,v| v.nil? }

        Response.build h, type
      else
        json = JSON.load(response.empty? ? '{}' : response)
        raise FailedResponse.new(json['message'], json['code'], req) if json.delete('stat') == 'fail'
        type, json = json.to_a.first if json.size == 1 and json.all? { |k,v| v.is_a? Hash }

        Response.build json, type
      end
    end

    def upload_flickr(method, file, args={})
      oauth_args = args.delete(:oauth) || {}
      args = build_args(args)
      if file.respond_to? :read
        args['photo'] = file
      else
        args['photo'] = open(file, 'rb')
        close_after = true
      end

      http_response = @oauth_consumer.post_multipart(method, @access_secret, {:oauth_token => @access_token}.merge(oauth_args), args)
      args['photo'].close if close_after
      process_response(method, http_response.body)
    end

  end

end
