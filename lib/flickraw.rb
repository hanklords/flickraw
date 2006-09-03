# Copyright (c) 2006 Hank Lords <hanklords@gmail.com>
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


require 'rexml/document'
require 'net/http'
require 'md5'

module FlickRaw
  VERSION='0.3.1'

  FLICKR_HOST='api.flickr.com'.freeze

  # Path of flickr REST API
  REST_PATH='/services/rest/?'.freeze

  # Path of flickr auth page
  AUTH_PATH='/services/auth/?'.freeze

  # Path of flickr upload
  UPLOAD_PATH='/services/upload/'.freeze

  @api_key = '7b124df89b638e545e3165293883ef62'

  # This is a wrapper around the xml response which provides an easy interface.
  class Xml
    # Returns the text content of the response
    attr_reader :to_s

    # Returns the raw xml of the response
    attr_reader :to_xml

    def initialize(xml) # :nodoc:
      @to_s   = xml.texts.join(' ')
      @to_xml = xml.to_s
      @list = nil

      xml.attributes.each {|a, v| attribute a, v }

      if xml.name =~ /s\z/
        elements = REXML::XPath.match( xml, xml.name.sub(/s\z/, ''))
        unless elements.empty?
          @list = elements.collect { |e| Xml.new e }
        end
      else
        xml.elements.each {|e| attribute e.name, Xml.new(e) }
      end
    end

    def respond_to?(m) # :nodoc:
      super || @list.respond_to?(m)
    end

    private
    def method_missing(sym, *args, &block)
      if @list.respond_to?( sym)
        @list.send sym, *args, &block
      else
        super
      end
    end

    def attribute(sym, value)
      meta = class << self; self; end
      meta.class_eval { define_method(sym) { value } }
    end
  end

  # This is what you get in response to an API call.
  class Response < Xml
    # This is called internally. It builds the response object according to xml response from the server.
    def initialize(raw_xml)
      doc = REXML::Document.new raw_xml
      super doc.root
      super doc.root.elements[1] if doc.root.elements.size == 1
    end
  end

  class FailedResponse < StandardError
    attr_reader :code
    alias :msg :message
    def initialize(msg, code)
      @code = code
      super( msg)
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
        if const_defined? class_name
          klass = const_get( class_name)
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
    def self.flickr_objects
      @flickr_objects ||= []
    end

    # List of the flickr methods of this object
    def self.flickr_methods
      @flickr_methods ||= []
    end

    # Returns the prefix of the request corresponding to this class.
    def self.request_name
      class_req = name.downcase.gsub( /::/, '.')
      class_req.sub( /[^\.]+\./, '')              # Removes RawFlickr at the beginning
    end
  end

  # Root class of the flickr api hierarchy.
  class Flickr < Request
    def initialize # :nodoc:
      super self
      @token = nil
    end

    # This is the central method. It does the actual request to the flickr server.
    #
    # Raises FailedResponse if the response status is _failed_.
    def call(req, args={})
      path = REST_PATH + build_args(args, req).collect { |a, v| "#{a}=#{v}" }.join('&')

      http_response = Net::HTTP.start(FLICKR_HOST) { |http|
        http.get(path, 'User-Agent' => "Flickraw/#{VERSION}")
      }
      res = Response.new http_response.body
      raise FailedResponse.new(res.msg, res.code) if res.stat == 'fail'
      lookup_token(req, res)
      res
    end

    # Use this to upload the photo in _file_.
    #
    #  flickr.upload_photo '/path/to/the/photo', :title => 'Title', :description => 'This is the description'
    #
    # See http://www.flickr.com/services/api/upload.api.html for more information on the arguments.
    def upload_photo(file, args={})
      photo = File.read file
      boundary = MD5.md5(photo).to_s

      header = {'Content-type' => "multipart/form-data, boundary=#{boundary} ", 'User-Agent' => "Flickraw/#{VERSION}"}
      query = build_args(args).collect { |a, v|
        "--#{boundary}\r\n" <<
        "Content-Disposition: form-data; name=\"#{a}\"\r\n\r\n" <<
        "#{v}\r\n"
      }.join('')
      query << "--#{boundary}\r\n" <<
               "Content-Disposition: form-data; name=\"photo\"; filename=\"#{file}\"\r\n" <<
               "Content-Transfer-Encoding: binary\r\n" <<
               "Content-Type: image/jpeg\r\n\r\n" <<
               photo <<
               "\r\n" <<
               "--#{boundary}--"

      http_response = Net::HTTP.start(FLICKR_HOST) { |http|
        http.post(UPLOAD_PATH, query, header)
      }
      res = Response.new http_response.body
      raise FailedResponse.new(res.msg, res.code) if res.stat == 'fail'
      res
    end

    private
    def build_args(args={}, req = nil)
      full_args = {:api_key => FlickRaw.api_key}
      full_args[:method] = req if req
      full_args[:auth_token] = @token if @token
      args.each {|k, v| full_args[k.to_sym] = v }
      full_args[:api_sig] = FlickRaw.api_sig(full_args) if FlickRaw.shared_secret
      full_args
    end

    def lookup_token(req, res)
      token_reqs = ['flickr.auth.getToken', 'flickr.auth.getFullToken', 'flickr.auth.checkToken']
      @token = res.token if token_reqs.include?(req) and res.respond_to?( :token)
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

      'http://' + FLICKR_HOST + AUTH_PATH + full_args.collect { |a, v| "#{a}=#{v}" }.join('&')
    end

    # Returns the signature of hsh. This is meant to be passed in the _api_sig_ parameter.
    def api_sig(hsh)
      MD5.md5(FlickRaw.shared_secret + hsh.sort{|a, b| a[0].to_s <=> b[0].to_s }.flatten.join).to_s
    end
  end

  methods = Flickr.new.call 'flickr.reflection.getMethods'
  methods.each { |method| Flickr.build_request method.to_s }
end

class Object
  # Use this to access the flickr API easily. You can type directly the flickr requests as they are described on the flickr website.
  #  require 'flickraw'
  #
  #  recent_photos = flickr.photos.getRecent
  #  puts recent_photos[0].title
  def flickr
    @flickr ||= FlickRaw::Flickr.new
  end
end
