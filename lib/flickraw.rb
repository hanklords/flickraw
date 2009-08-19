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
require 'digest/md5'
require 'json'
require 'cgi'

FlickrawOptions = {} if not Object.const_defined? :FlickrawOptions # :nodoc:
if ENV['http_proxy'] and not FlickrawOptions[:proxy_host]
  proxy = URI.parse ENV['http_proxy']
  FlickrawOptions.update(:proxy_host => proxy.host, :proxy_port => proxy.port, :proxy_user => proxy.user, :proxy_password => proxy.password)
end

module FlickRaw
  VERSION='0.7.1'

  FLICKR_HOST='api.flickr.com'.freeze

  # Path of flickr REST API
  REST_PATH='/services/rest/?'.freeze

  # Path of flickr auth page
  AUTH_PATH='http://flickr.com/services/auth/?'.freeze

  # Path of flickr upload
  UPLOAD_PATH='/services/upload/'.freeze

  @api_key = '7b124df89b638e545e3165293883ef62'

  class Response
    def self.build(h, name = '')
      if name =~ /s$/ and (a = h[$`]).is_a? Array
        ResponseList.new(h, a.collect {|e| Response.build(e)})
      elsif h.keys == ["_content"]
        h["_content"]
      else
	Response.new(h)
      end
    end

    def initialize(h)
      @h = {}
      methods = "class << self;"
      h.each {|k,v|
        @h[k] = case v
	when Hash  then self.build(v, k)
	when Array then v.collect {|e| Response.build(e)}
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
  end

  class ResponseList < Response
    include Enumerable
    def initialize(h, a); super(h); @a = a end
    def [](k); k.is_a?(Fixnum) ? @a[k] : super(k) end
    def each; @a.each{|e| yield e} end
    def to_a; @a end
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
        define_method(req) { |*args|
          class_req = self.class.request_name
          @flickr.call class_req + '.' + req, *args
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
    def self.build(methods); methods.each { |m| build_request m } end

    def initialize # :nodoc:
      Flickr.build(call('flickr.reflection.getMethods')) if Flickr.flickr_objects.empty?
      super self
      @token = nil
    end

    # This is the central method. It does the actual request to the flickr server.
    #
    # Raises FailedResponse if the response status is _failed_.
    def call(req, args={})
      path = REST_PATH + build_args(args, req).collect { |a, v| "#{a}=#{v}" }.join('&')
      http_response = open_flickr {|http| http.get(path, 'User-Agent' => "Flickraw/#{VERSION}") }
      parse_response(http_response, req)
    end

    # Use this to upload the photo in _file_.
    #
    #  flickr.upload_photo '/path/to/the/photo', :title => 'Title', :description => 'This is the description'
    #
    # See http://www.flickr.com/services/api/upload.api.html for more information on the arguments.
    def upload_photo(file, args={})
      photo = File.open(file, 'rb') { |f| f.read }
      boundary = Digest::MD5.hexdigest(photo)

      header = {'Content-type' => "multipart/form-data, boundary=#{boundary} ", 'User-Agent' => "Flickraw/#{VERSION}"}
      query = ''
      build_args(args).each { |a, v|
        query <<
          "--#{boundary}\r\n" <<
          "Content-Disposition: form-data; name=\"#{a}\"\r\n\r\n" <<
          "#{v}\r\n"
      }
      query <<
        "--#{boundary}\r\n" <<
        "Content-Disposition: form-data; name=\"photo\"; filename=\"#{file}\"\r\n" <<
        "Content-Transfer-Encoding: binary\r\n" <<
        "Content-Type: image/jpeg\r\n\r\n" <<
        photo <<
        "\r\n" <<
        "--#{boundary}--"

      http_response = open_flickr {|http| http.post(UPLOAD_PATH, query, header) }
      xml = http_response.body
      if xml[/stat="(\w+)"/, 1] == 'fail'
        msg = xml[/msg="([^"]+)"/, 1]
        code = xml[/code="([^"]+)"/, 1]
        raise FailedResponse.new(msg, code, 'flickr.upload')
      end
      Response.structify( {:stat => 'ok', :photoid => xml[/<photoid>(\w+)<\/photoid>/, 1], :ticketid => xml[/<ticketid>([^<]+)<\/ticketid>/, 1]})
    end

    private
    def parse_response(response, req = nil)
      json = JSON.load(response.body)
      raise FailedResponse.new(json['message'], json['code'], req) if json.delete('stat') == 'fail'
      name, json = json.to_a.first if json.size == 1

      res = Response.build json, name
      lookup_token(req, res)
      res
    end

    def build_args(args={}, req = nil)
      full_args = {:api_key => FlickRaw.api_key, :format => 'json', :nojsoncallback => 1}
      full_args[:method] = req if req
      full_args[:auth_token] = @token if @token
      args.each {|k, v| full_args[k.to_sym] = v.to_s }
      full_args[:api_sig] = FlickRaw.api_sig(full_args) if FlickRaw.shared_secret
      args.each {|k, v| full_args[k.to_sym] = CGI.escape(v.to_s) } if req
      full_args
    end

    def lookup_token(req, res)
      token_reqs = ['flickr.auth.getToken', 'flickr.auth.getFullToken', 'flickr.auth.checkToken']
      @token = res.token if token_reqs.include?(req) and res.respond_to?(:token)
    end

    def open_flickr
      Net::HTTP::Proxy(FlickrawOptions[:proxy_host], FlickrawOptions[:proxy_port], FlickrawOptions[:proxy_user], FlickrawOptions[:proxy_password]).start(FLICKR_HOST) {|http|
        http.read_timeout = FlickrawOptions[:timeout] if FlickrawOptions[:timeout]
        yield http
      }
    end
  end

  class << self
    # Your flickr API key, see http://www.flickr.com/services/api/keys for more information
    attr_accessor :api_key

    # The shared secret of _api_key_, see http://www.flickr.com/services/api/keys for more information
    attr_accessor :shared_secret

    # Returns the flickr auth URL.
    def auth_url(args={})
      full_args = {:api_key => FlickRaw.api_key, :perms => 'read'}
      args.each {|k, v| full_args[k.to_sym] = v }
      full_args[:api_sig] = api_sig(full_args) if FlickRaw.shared_secret

      AUTH_PATH + full_args.collect { |a, v| "#{a}=#{v}" }.join('&')
    end

    # Returns the signature of hsh. This is meant to be passed in the _api_sig_ parameter.
    def api_sig(hsh)
      Digest::MD5.hexdigest(FlickRaw.shared_secret + hsh.sort{|a, b| a[0].to_s <=> b[0].to_s }.flatten.join)
    end
  end
end

# Use this to access the flickr API easily. You can type directly the flickr requests as they are described on the flickr website.
#  require 'flickraw'
#
#  recent_photos = flickr.photos.getRecent
#  puts recent_photos[0].title
def flickr; $flickraw ||= FlickRaw::Flickr.new end

# Load the methods if the option lazyload is not specified
flickr if not FlickrawOptions[:lazyload]
