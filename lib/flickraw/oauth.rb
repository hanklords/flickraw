require 'openssl'
require 'net/https'

module FlickRaw
  class OAuthClient
    class UnknownSignatureMethod < Error; end
    class FailedResponse < Error
      def initialize(str)
        @response = OAuthClient.parse_response(str)
        super(@response['oauth_problem'])
      end
    end

    class << self
      def encode_value(v)
        v = v.to_s.encode("utf-8").force_encoding("ascii-8bit") if RUBY_VERSION >= "1.9"
        v.to_s
      end

      def escape(s)
        encode_value(s).gsub(/[^a-zA-Z0-9\-\.\_\~]/) { |special|
          special.unpack("C*").map{|i| sprintf("%%%02X", i) }.join
        }
      end

      def parse_response(text); Hash[text.split("&").map {|s| s.split("=")}] end

      def signature_base_string(method, url, params)
        params_norm = params.map {|k,v| escape(k) + "=" + escape(v)}.sort.join("&")
        method.to_s.upcase + "&" + escape(url) + "&" + escape(params_norm)
      end
      
      def sign_plaintext(method, url, params, token_secret, consumer_secret)
        escape(consumer_secret) + "&" + escape(token_secret)
      end
        
      def sign_rsa_sha1(method, url, params, token_secret, consumer_secret)
        text = signature_base_string(method, url, params)
        key = OpenSSL::PKey::RSA.new(consumer_secret)
        digest = OpenSSL::Digest::SHA1.new
        [key.sign(digest, text)].pack('m0').gsub(/\n$/,'')
      end
            
      def sign_hmac_sha1(method, url, params, token_secret, consumer_secret)
        text = signature_base_string(method, url, params)
        key = escape(consumer_secret) + "&" + escape(token_secret)
        digest = OpenSSL::Digest::SHA1.new
        [OpenSSL::HMAC.digest(digest, key, text)].pack('m0').gsub(/\n$/,'')
      end
    
      def gen_timestamp; Time.now.to_i end
      def gen_nonce; [OpenSSL::Random.random_bytes(32)].pack('m0').gsub(/\n$/,'') end
      def gen_default_params
        { :oauth_version => "1.0", :oauth_signature_method => "HMAC-SHA1",
          :oauth_nonce => gen_nonce, :oauth_timestamp => gen_timestamp }
      end
    
      def authorization_header(url, params)
        params_norm = params.map {|k,v| %(#{escape(k)}="#{escape(v)}")}.sort.join(", ")
        %(OAuth realm="#{url.to_s}", #{params_norm})
      end
    end
    
    attr_accessor :user_agent
    attr_reader :proxy
    attr_accessor :check_certificate
    attr_accessor :ca_file
    attr_accessor :ca_path
    def proxy=(url); @proxy = URI.parse(url || '') end
    
    def initialize(consumer_key, consumer_secret)
      @consumer_key, @consumer_secret = consumer_key, consumer_secret
      self.proxy = nil
    end

    def request_token(url, oauth_params = {})
      r = post_form(url, nil, {:oauth_callback => "oob"}.merge(oauth_params))
      OAuthClient.parse_response(r.body)
    end
    
    def authorize_url(url, oauth_params = {})
      params_norm = oauth_params.map {|k,v| OAuthClient.escape(k) + "=" + OAuthClient.escape(v)}.sort.join("&")
      url =  URI.parse(url)
      url.query = url.query ? url.query + "&" + params_norm : params_norm
      url.to_s
    end
    
    def access_token(url, token_secret, oauth_params = {})
      r = post_form(url, token_secret, oauth_params)
      OAuthClient.parse_response(r.body)
    end

    def post_form(url, token_secret, oauth_params = {}, params = {})
      encoded_params = Hash[*params.map {|k,v| [OAuthClient.encode_value(k), OAuthClient.encode_value(v)]}.flatten]
      post(url, token_secret, oauth_params, params) {|request| request.form_data = encoded_params}
    end
    
    def post_multipart(url, token_secret, oauth_params = {}, params = {})
      post(url, token_secret, oauth_params, params) {|request|
        boundary = "FlickRaw#{OAuthClient.gen_nonce}"
        request['Content-type'] = "multipart/form-data, boundary=#{boundary}"

        request.body = ''
        params.each { |k, v|
          if v.respond_to? :read
            basename = File.basename(v.path.to_s) if v.respond_to? :path
            basename ||= File.basename(v.base_uri.to_s) if v.respond_to? :base_uri
            basename ||= "unknown"
            request.body << "--#{boundary}\r\n" <<
              "Content-Disposition: form-data; name=\"#{OAuthClient.encode_value(k)}\"; filename=\"#{OAuthClient.encode_value(basename)}\"\r\n" <<
              "Content-Transfer-Encoding: binary\r\n" <<
              "Content-Type: image/jpeg\r\n\r\n" <<
              v.read << "\r\n"
          else
            request.body << "--#{boundary}\r\n" <<
              "Content-Disposition: form-data; name=\"#{OAuthClient.encode_value(k)}\"\r\n\r\n" <<
              "#{OAuthClient.encode_value(v)}\r\n"
          end
        }
        
        request.body << "--#{boundary}--"
      }
    end

    private
    def sign(method, url, params, token_secret = nil)
      case params[:oauth_signature_method]
      when "HMAC-SHA1"
        OAuthClient.sign_hmac_sha1(method, url, params, token_secret, @consumer_secret)
      when "RSA-SHA1"
        OAuthClient.sign_rsa_sha1(method, url, params, token_secret, @consumer_secret)
      when "PLAINTEXT"
        OAuthClient.sign_plaintext(method, url, params, token_secret, @consumer_secret)
      else
        raise UnknownSignatureMethod, params[:oauth_signature_method]
      end
    end

    def post(url, token_secret, oauth_params, params)
      url = URI.parse(url)
      default_oauth_params = OAuthClient.gen_default_params
      default_oauth_params[:oauth_consumer_key] = @consumer_key
      default_oauth_params[:oauth_signature_method] = "PLAINTEXT" if url.scheme == 'https'
      oauth_params = default_oauth_params.merge(oauth_params)
      params_signed = params.reject {|k,v| v.respond_to? :read}.merge(oauth_params)
      oauth_params[:oauth_signature] = sign(:post, url, params_signed, token_secret)

      http = Net::HTTP.new(url.host, url.port, @proxy.host, @proxy.port, @proxy.user, @proxy.password)
      http.use_ssl = (url.scheme == 'https')
      http.verify_mode = (@check_certificate ? OpenSSL::SSL::VERIFY_PEER : OpenSSL::SSL::VERIFY_NONE)
      http.ca_file = @ca_file
      http.ca_path = @ca_path
      r = http.start {|agent|
        request = Net::HTTP::Post.new(url.path)
        request['User-Agent'] = @user_agent if @user_agent
        request['Authorization'] = OAuthClient.authorization_header(url, oauth_params)

        yield request
        agent.request(request)
      }
      
      raise FailedResponse.new(r.body) if r.is_a? Net::HTTPClientError
      r
    end
  end

end
