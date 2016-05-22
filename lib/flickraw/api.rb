module FlickRaw
  END_POINT='http://api.flickr.com/services'.freeze
  END_POINT2='http://www.flickr.com/services'.freeze
  END_POINT_SECURE='https://api.flickr.com/services'.freeze
  
  FLICKR_OAUTH_REQUEST_TOKEN=(END_POINT2 + '/oauth/request_token').freeze
  FLICKR_OAUTH_AUTHORIZE=(END_POINT2 + '/oauth/authorize').freeze
  FLICKR_OAUTH_ACCESS_TOKEN=(END_POINT2 + '/oauth/access_token').freeze
  
  FLICKR_OAUTH_REQUEST_TOKEN_SECURE=(END_POINT_SECURE + '/oauth/request_token').freeze
  FLICKR_OAUTH_AUTHORIZE_SECURE=(END_POINT_SECURE + '/oauth/authorize').freeze
  FLICKR_OAUTH_ACCESS_TOKEN_SECURE=(END_POINT_SECURE + '/oauth/access_token').freeze

  REST_PATH=(END_POINT + '/rest/').freeze
  UPLOAD_PATH=(END_POINT + '/upload/').freeze
  REPLACE_PATH=(END_POINT + '/replace/').freeze
  
  REST_PATH_SECURE=(END_POINT_SECURE + '/rest/').freeze
  UPLOAD_PATH_SECURE=(END_POINT_SECURE + '/upload/').freeze
  REPLACE_PATH_SECURE=(END_POINT_SECURE + '/replace/').freeze

  PHOTO_SOURCE_URL='https://farm%s.staticflickr.com/%s/%s_%s%s.%s'.freeze
  URL_PROFILE='https://www.flickr.com/people/'.freeze
  URL_PHOTOSTREAM='https://www.flickr.com/photos/'.freeze
  URL_SHORT='https://flic.kr/p/'.freeze

  class FlickrAppNotConfigured < Error; end

  # Root class of the flickr api hierarchy.
  class Flickr < Request
    # Authenticated access token
    attr_accessor :access_token
    
    # Authenticated access token secret
    attr_accessor :access_secret
    
    def self.build(methods); methods.each { |m| build_request m } end

    def initialize(api_key: FlickRaw.api_key,
                   shared_secret: FlickRaw.shared_secret)
      if api_key.nil?
        raise FlickrAppNotConfigured.new("No API key defined!")
      end
      if shared_secret.nil?
        raise FlickrAppNotConfigured.new("No shared secret defined!")
      end
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
      rest_path = FlickRaw.secure ? REST_PATH_SECURE :  REST_PATH
      http_response = @oauth_consumer.post_form(rest_path, @access_secret, {:oauth_token => @access_token}.merge(oauth_args), build_args(args, req))
      process_response(req, http_response.body)
    end

    # Get an oauth request token.
    #
    #    token = flickr.get_request_token(:oauth_callback => "http://example.com")
    def get_request_token(args = {})
      flickr_oauth_request_token = FlickRaw.secure ? FLICKR_OAUTH_REQUEST_TOKEN_SECURE : FLICKR_OAUTH_REQUEST_TOKEN
      @oauth_consumer.request_token(flickr_oauth_request_token, args)
    end
    
    # Get the oauth authorize url.
    #
    #  auth_url = flickr.get_authorize_url(token['oauth_token'], :perms => 'delete')
    def get_authorize_url(token, args = {})
      flickr_oauth_authorize = FlickRaw.secure ? FLICKR_OAUTH_AUTHORIZE_SECURE : FLICKR_OAUTH_AUTHORIZE
      @oauth_consumer.authorize_url(flickr_oauth_authorize, args.merge(:oauth_token => token))
    end

    # Get an oauth access token.
    #
    #  flickr.get_access_token(token['oauth_token'], token['oauth_token_secret'], oauth_verifier)
    def get_access_token(token, secret, verify)
      flickr_oauth_access_token = FlickRaw.secure ? FLICKR_OAUTH_ACCESS_TOKEN_SECURE : FLICKR_OAUTH_ACCESS_TOKEN
      access_token = @oauth_consumer.access_token(flickr_oauth_access_token, secret, :oauth_token => token, :oauth_verifier => verify)
      @access_token, @access_secret = access_token['oauth_token'], access_token['oauth_token_secret']
      access_token
    end

    # Use this to upload the photo in _file_.
    #
    #  flickr.upload_photo '/path/to/the/photo', :title => 'Title', :description => 'This is the description'
    #
    # See http://www.flickr.com/services/api/upload.api.html for more information on the arguments.
    def upload_photo(file, args={})
      upload_path = FlickRaw.secure ? UPLOAD_PATH_SECURE : UPLOAD_PATH
      upload_flickr(upload_path, file, args)
    end

    # Use this to replace the photo with :photo_id with the photo in _file_.
    #
    #  flickr.replace_photo '/path/to/the/photo', :photo_id => id
    #
    # See http://www.flickr.com/services/api/replace.api.html for more information on the arguments.
    def replace_photo(file, args={})
      replace_path = FlickRaw.secure ? REPLACE_PATH_SECURE : REPLACE_PATH
      upload_flickr(replace_path, file, args)
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
          "secret" => response[/secret="([^"]+)"/, 1],
          "originalsecret" => response[/originalsecret="([^"]+)"/, 1],
          "_content" => response[/>([^<]+)<\//, 1]
        }.delete_if {|k,v| v.nil? }
        
        Response.build h, type
      else
        json = JSON.load(response.empty? ? "{}" : response)
        raise FailedResponse.new(json['message'], json['code'], req) if json.delete('stat') == 'fail'
        type, json = json.to_a.first if json.size == 1 and json.all? {|k,v| v.is_a? Hash}

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

  class << self
    # Your flickr API key, see http://www.flickr.com/services/api/keys for more information
    attr_accessor :api_key
    
    # The shared secret of _api_key_, see http://www.flickr.com/services/api/keys for more information
    attr_accessor :shared_secret
    
    # Use a proxy
    attr_accessor :proxy
    
    # Use ssl connection
    attr_accessor :secure

    # Check the server certificate (ssl connection only)
    attr_accessor :check_certificate
    
    # Set path of a CA certificate file in PEM format (ssl connection only)
    attr_accessor :ca_file

    # Set path to a directory of CA certificate files in PEM format (ssl connection only)
    attr_accessor :ca_path

    BASE58_ALPHABET="123456789abcdefghijkmnopqrstuvwxyzABCDEFGHJKLMNPQRSTUVWXYZ".freeze
    def base58(id)
      id = id.to_i
      alphabet = BASE58_ALPHABET.split(//)
      base = alphabet.length
      begin
        id, m = id.divmod(base)
        r = alphabet[m] + (r || '')
      end while id > 0
      r
    end

    def url(r);   PHOTO_SOURCE_URL % [r.farm, r.server, r.id, r.secret, "",   "jpg"]   end
    def url_m(r); PHOTO_SOURCE_URL % [r.farm, r.server, r.id, r.secret, "_m", "jpg"] end
    def url_s(r); PHOTO_SOURCE_URL % [r.farm, r.server, r.id, r.secret, "_s", "jpg"] end
    def url_t(r); PHOTO_SOURCE_URL % [r.farm, r.server, r.id, r.secret, "_t", "jpg"] end
    def url_b(r); PHOTO_SOURCE_URL % [r.farm, r.server, r.id, r.secret, "_b", "jpg"] end
    def url_z(r); PHOTO_SOURCE_URL % [r.farm, r.server, r.id, r.secret, "_z", "jpg"] end
    def url_q(r); PHOTO_SOURCE_URL % [r.farm, r.server, r.id, r.secret, "_q", "jpg"] end
    def url_n(r); PHOTO_SOURCE_URL % [r.farm, r.server, r.id, r.secret, "_n", "jpg"] end
    def url_c(r); PHOTO_SOURCE_URL % [r.farm, r.server, r.id, r.secret, "_c", "jpg"] end
    def url_o(r); PHOTO_SOURCE_URL % [r.farm, r.server, r.id, r.originalsecret, "_o", r.originalformat] end
    def url_profile(r); URL_PROFILE + (r.owner.respond_to?(:nsid) ? r.owner.nsid : r.owner) + "/" end
    def url_photopage(r); url_photostream(r) + r.id end
    def url_photosets(r); url_photostream(r) + "sets/" end
    def url_photoset(r); url_photosets(r) + r.id end
    def url_short(r); URL_SHORT + base58(r.id) end
    def url_short_m(r); URL_SHORT + "img/" + base58(r.id) + "_m.jpg" end
    def url_short_s(r); URL_SHORT + "img/" + base58(r.id) + ".jpg" end
    def url_short_t(r); URL_SHORT + "img/" + base58(r.id) + "_t.jpg" end
    def url_short_q(r); URL_SHORT + "img/" + base58(r.id) + "_q.jpg" end
    def url_short_n(r); URL_SHORT + "img/" + base58(r.id) + "_n.jpg" end
    def url_photostream(r)
      URL_PHOTOSTREAM +
        if r.respond_to?(:pathalias) and r.pathalias
          r.pathalias
        elsif r.owner.respond_to?(:nsid)
          r.owner.nsid
        else
          r.owner
        end + "/"
    end
  end
end
