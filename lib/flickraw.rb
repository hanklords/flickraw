# encoding: ascii-8bit
# Copyright (c) 2006 Mael Clerambault <maelclerambault@yahoo.fr>
#
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
# IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
# CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
# TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
# SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.


require 'net/http'
require 'json'

module FlickRaw
  VERSION='0.8.4'
  USER_AGENT = "Flickraw/#{VERSION}"

  FLICKR_OAUTH_REQUEST_TOKEN='http://www.flickr.com/services/oauth/request_token'.freeze
  FLICKR_OAUTH_AUTHORIZE='http://www.flickr.com/services/oauth/authorize'.freeze
  FLICKR_OAUTH_ACCESS_TOKEN='http://www.flickr.com/services/oauth/access_token'.freeze

  REST_PATH='http://api.flickr.com/services/rest/'.freeze
  UPLOAD_PATH='http://api.flickr.com/services/upload/'.freeze
  REPLACE_PATH='http://api.flickr.com/services/replace/'.freeze

  PHOTO_SOURCE_URL='http://farm%s.static.flickr.com/%s/%s_%s%s.%s'.freeze
  URL_PROFILE='http://www.flickr.com/people/'.freeze
  URL_PHOTOSTREAM='http://www.flickr.com/photos/'.freeze
  URL_SHORT='http://flic.kr/p/'.freeze
  
  class OAuth
    class FailedResponse < StandardError
      def initialize(str)
        @response = OAuth.parse_response(str)
        super(@response['oauth_problem'])
      end
    end
  
    class << self
      def escape(v); URI.escape(v.to_s, /[^a-zA-Z0-9\-\.\_\~]/) end
      def parse_response(text); Hash[text.split("&").map {|s| s.split("=")}] end
    end
    
    attr_accessor :user_agent
    attr_reader :proxy
    def proxy=(url)
      return if url.nil?
      @proxy = URI.parse(url)
      @proxy_host, @proxy_port, @proxy_user, @proxy_password = @proxy.host, @proxy.port, @proxy.user, @proxy.password
      @proxy
    end
    
    def initialize(consumer_key, consumer_secret); @consumer_key, @consumer_secret = consumer_key, consumer_secret end

    def sign(method, url, params, token_secret = nil, consumer_secret = @consumer_secret)
      params_norm = params.map {|k,v| OAuth.escape(k) + "=" + OAuth.escape(v) }.sort.join("&")
      text = method.to_s.upcase + "&" + OAuth.escape(url) + "&" + OAuth.escape(params_norm)
      key = consumer_secret.to_s + "&" + token_secret.to_s
      digest = OpenSSL::Digest::Digest.new("sha1")
      [OpenSSL::HMAC.digest(digest, key, text)].pack('m0')
    end
    
    def authorization_header(url, params)
      params_norm = params.map {|k,v| OAuth.escape(k) + "=\"" + OAuth.escape(v) + "\""}.sort.join(", ")
      "OAuth realm=\"" + url.to_s + "\", " + params_norm
    end
    
    def gen_timestamp; Time.now.to_i end
    def gen_nonce; [OpenSSL::Random.random_bytes(32)].pack('m0') end
    def gen_default_params
      { :oauth_version => "1.0", :oauth_signature_method => "HMAC-SHA1",
        :oauth_consumer_key => @consumer_key, :oauth_nonce => gen_nonce,
        :oauth_timestamp => gen_timestamp }
    end
    
    def request_token(url, oauth_params = {})
      r = post_form(url, token_secret, {:oauth_callback => "oob"}.merge(oauth_params))
      OAuth.parse_response(r.body)
    end
    
    def authorize_url(url, oauth_params = {})
      params_norm = oauth_params.map {|k,v| OAuth.escape(k) + "=" + OAuth.escape(v)}.sort.join("&")
      url =  URI.parse(url)
      url.query = url.query ? url.query + "&" + params_norm : params_norm
      url
    end
    
    def access_token(url, token_secret, oauth_params = {})
      r = post_form(url, token_secret, oauth_params)
      OAuth.parse_response(r.body)
    end
        
    def post_form(url, token_secret, oauth_params = {}, params = {})
      oauth_params = gen_default_params.merge(oauth_params)
      oauth_params[:oauth_signature] = sign(:post, url, params.merge(oauth_params), token_secret)
      url = URI.parse(url)
      r = Net::HTTP.start(url.host, url.port, @proxy_host, @proxy_port, @proxy_user, @proxy_password) { |http| 
        request = Net::HTTP::Post.new(url.path)
        request['User-Agent'] = @user_agent if @user_agent
        request['Authorization'] = authorization_header(url, oauth_params)
        request.form_data = params
        http.request(request)
      }
      
      raise FailedResponse.new(r.body) if r.is_a? Net::HTTPClientError
      r
    end
    
    def post_multipart(url, token_secret, oauth_params = {}, params = {})
      oauth_params = gen_default_params.merge(oauth_params)
      params_signed = params.reject {|k,v| v.is_a? File}.merge(oauth_params)
      oauth_params[:oauth_signature] = sign(:post, url, params_signed, token_secret)
      url = URI.parse(url)
      r = Net::HTTP.start(url.host, url.port, @proxy_host, @proxy_port, @proxy_user, @proxy_password) { |http| 
        boundary = "FlickRaw#{gen_nonce}"
        request = Net::HTTP::Post.new(url.path)
        request['User-Agent'] = @user_agent if @user_agent
        request['Content-type'] = "multipart/form-data, boundary=#{boundary}"
        request['Authorization'] = authorization_header(url, oauth_params)

        request.body = ''
        params.each { |k, v|
          if v.is_a? File
            filename = File.basename(v.path).to_s.encode("utf-8").force_encoding("ascii-8bit")
            request.body << "--#{boundary}\r\n" <<
              "Content-Disposition: form-data; name=\"#{k}\"; filename=\"#{filename}\"\r\n" <<
              "Content-Transfer-Encoding: binary\r\n" <<
              "Content-Type: image/jpeg\r\n\r\n" <<
              v.read << "\r\n"
          else
            request.body << "--#{boundary}\r\n" <<
              "Content-Disposition: form-data; name=\"#{k}\"\r\n\r\n" <<
              "#{v}\r\n"
          end
        }
        
        request.body << "--#{boundary}--"
        http.request(request)
      }
      
      raise FailedResponse.new(r.body) if r.is_a? Net::HTTPClientError
      r      
    end    
  end

  class Response
    def self.build(h, type) # :nodoc:
      if h.is_a? Response
        h
      elsif type =~ /s$/ and (a = h[$`]).is_a? Array
        ResponseList.new(h, type, a.collect {|e| Response.build(e, $`)})
      elsif h.keys == ["_content"]
        h["_content"]
      else
        Response.new(h, type)
      end
    end

    attr_reader :flickr_type
    def initialize(h, type) # :nodoc:
      @flickr_type, @h = type, {}
      methods = "class << self;"
      h.each {|k,v|
        @h[k] = case v
          when Hash  then Response.build(v, k)
          when Array then v.collect {|e| Response.build(e, k)}
          else v
        end
        methods << "def #{k}; @h['#{k}'] end;"
      }
      eval methods << "end"
    end
    def [](k); @h[k] end
    def to_s; @h["_content"] || super end
    def inspect; @h.inspect end
    def to_hash; @h end
    def marshal_dump; [@h, @flickr_type] end
    def marshal_load(data); initialize(*data) end
  end

  class ResponseList < Response
    include Enumerable
    def initialize(h, t, a); super(h, t); @a = a end
    def [](k); k.is_a?(Fixnum) ? @a[k] : super(k) end
    def each; @a.each{|e| yield e} end
    def to_a; @a end
    def inspect; @a.inspect end
    def size; @a.size end
    def marshal_dump; [@h, @flickr_type, @a] end
    alias length size
  end

  class FailedResponse < StandardError
    attr_reader :code
    alias :msg :message
    def initialize(msg, code, req)
      @code = code
      super("'#{req}' - #{msg}")
    end
  end

  class Request
    def initialize(flickr = nil) # :nodoc:
      @flickr = flickr

      self.class.flickr_objects.each {|name|
        klass = self.class.const_get name.capitalize
        instance_variable_set "@#{name}", klass.new(@flickr)
      }
    end

    def self.build_request(req) # :nodoc:
      method_nesting = req.split '.'
      raise "'#{@name}' : Method name mismatch" if method_nesting.shift != request_name.split('.').last

      if method_nesting.size > 1
        name = method_nesting.first
        class_name = name.capitalize
        if flickr_objects.include? name
          klass = const_get(class_name)
        else
          klass = Class.new Request
          const_set(class_name, klass)
          attr_reader name
          flickr_objects << name
        end

        klass.build_request method_nesting.join('.')
      else
        req = method_nesting.first
        module_eval %{
          def #{req}(*args, &block)
            @flickr.call("#{request_name}.#{req}", *args, &block)
          end
        }
        flickr_methods << req
      end
    end

    # List of the flickr subobjects of this object
    def self.flickr_objects; @flickr_objects ||= [] end

    # List of the flickr methods of this object
    def self.flickr_methods; @flickr_methods ||= [] end

    # Returns the prefix of the request corresponding to this class.
    def self.request_name; name.downcase.gsub(/::/, '.').sub(/[^\.]+\./, '') end
  end

  # Root class of the flickr api hierarchy.
  class Flickr < Request
    attr_accessor :access_token, :access_secret
    
    def self.build(methods); methods.each { |m| build_request m } end

    def initialize # :nodoc:
      raise "No API key or secret defined !" if FlickRaw.api_key.nil? or FlickRaw.shared_secret.nil?
      @oauth_consumer = OAuth.new(FlickRaw.api_key, FlickRaw.shared_secret)
      @oauth_consumer.proxy = FlickRaw.proxy
      @oauth_consumer.user_agent = USER_AGENT
      
      Flickr.build(call('flickr.reflection.getMethods')) if Flickr.flickr_objects.empty?
      super self
    end
    
    # This is the central method. It does the actual request to the flickr server.
    #
    # Raises FailedResponse if the response status is _failed_.
    def call(req, args={}, &block)
      http_response = @oauth_consumer.post_form(REST_PATH, @access_secret, {:oauth_token => @access_token}, build_args(args, req))
      process_response(req, http_response.body)
    end

    def get_request_token(args = {})
      request_token = @oauth_consumer.request_token(FLICKR_OAUTH_REQUEST_TOKEN, args)
      authorize_url = @oauth_consumer.authorize_url(FLICKR_OAUTH_AUTHORIZE, args.merge(:oauth_token => request_token['oauth_token']))
      request_token.merge('oauth_authorize_url' => authorize_url)
    end

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
    def upload_photo(file, args={}); upload_flickr(UPLOAD_PATH, file, args) end

    # Use this to replace the photo with :photo_id with the photo in _file_.
    #
    #  flickr.replace_photo '/path/to/the/photo', :photo_id => id
    #
    # See http://www.flickr.com/services/api/replace.api.html for more information on the arguments.
    def replace_photo(file, args={}); upload_flickr(REPLACE_PATH, file, args) end

    private
    def build_args(args={}, method = nil)
      full_args = {'format' => 'json', :nojsoncallback => "1"}
      full_args['method'] = method if method
      args.each {|k, v|
        v = v.to_s.encode("utf-8").force_encoding("ascii-8bit") if RUBY_VERSION >= "1.9"
        full_args[k.to_s] = v
      }
      full_args
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
      args = build_args(args)
      args['photo'] = open(file, 'rb')
      http_response = @oauth_consumer.post_multipart(method, @access_secret, {:oauth_token => @access_token}, args)
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
    def url_o(r); PHOTO_SOURCE_URL % [r.farm, r.server, r.id, r.originalsecret, "_o", r.originalformat] end
    def url_profile(r); URL_PROFILE + (r.owner.respond_to?(:nsid) ? r.owner.nsid : r.owner) + "/" end
    def url_photopage(r); url_photostream(r) + r.id end
    def url_photosets(r); url_photostream(r) + "sets/" end
    def url_photoset(r); url_photosets(r) + r.id end
    def url_short(r); URL_SHORT + base58(r.id) end
    def url_short_m(r); URL_SHORT + "img/" + base58(r.id) + "_m.jpg" end
    def url_short_s(r); URL_SHORT + "img/" + base58(r.id) + ".jpg" end
    def url_short_t(r); URL_SHORT + "img/" + base58(r.id) + "_t.jpg" end
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

# Use this to access the flickr API easily. You can type directly the flickr requests as they are described on the flickr website.
#  require 'flickraw'
#
#  recent_photos = flickr.photos.getRecent
#  puts recent_photos[0].title
def flickr; $flickraw ||= FlickRaw::Flickr.new end
