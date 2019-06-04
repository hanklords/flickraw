require 'json'
require 'flickraw/version'
require 'flickraw/util'
require 'flickraw/error'
require 'flickraw/oauth_client'
require 'flickraw/request'
require 'flickraw/response'
require 'flickraw/flickr'

module FlickRaw
  USER_AGENT = "FlickRaw/#{VERSION}"

  END_POINT                  = 'https://api.flickr.com/services'.freeze
  UPLOAD_END_POINT           = 'https://up.flickr.com/services'.freeze

  FLICKR_OAUTH_REQUEST_TOKEN = (END_POINT + '/oauth/request_token').freeze
  FLICKR_OAUTH_AUTHORIZE     = (END_POINT + '/oauth/authorize').freeze
  FLICKR_OAUTH_ACCESS_TOKEN  = (END_POINT + '/oauth/access_token').freeze

  REST_PATH                  = (END_POINT + '/rest/').freeze
  UPLOAD_PATH                = (UPLOAD_END_POINT + '/upload/').freeze
  REPLACE_PATH               = (UPLOAD_END_POINT + '/replace/').freeze

  PHOTO_SOURCE_URL           = 'https://farm%s.staticflickr.com/%s/%s_%s%s.%s'.freeze
  URL_PROFILE                = 'https://www.flickr.com/people/'.freeze
  URL_PHOTOSTREAM            = 'https://www.flickr.com/photos/'.freeze
  URL_SHORT                  = 'https://flic.kr/p/'.freeze

  class FlickrAppNotConfigured < Error; end

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

    BASE58_ALPHABET='123456789abcdefghijkmnopqrstuvwxyzABCDEFGHJKLMNPQRSTUVWXYZ'.freeze
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

    def url(r);   PHOTO_SOURCE_URL % [r.farm, r.server, r.id, r.secret, '',   'jpg'] end
    def url_m(r); PHOTO_SOURCE_URL % [r.farm, r.server, r.id, r.secret, '_m', 'jpg'] end
    def url_s(r); PHOTO_SOURCE_URL % [r.farm, r.server, r.id, r.secret, '_s', 'jpg'] end
    def url_t(r); PHOTO_SOURCE_URL % [r.farm, r.server, r.id, r.secret, '_t', 'jpg'] end
    def url_b(r); PHOTO_SOURCE_URL % [r.farm, r.server, r.id, r.secret, '_b', 'jpg'] end
    def url_z(r); PHOTO_SOURCE_URL % [r.farm, r.server, r.id, r.secret, '_z', 'jpg'] end
    def url_q(r); PHOTO_SOURCE_URL % [r.farm, r.server, r.id, r.secret, '_q', 'jpg'] end
    def url_n(r); PHOTO_SOURCE_URL % [r.farm, r.server, r.id, r.secret, '_n', 'jpg'] end
    def url_c(r); PHOTO_SOURCE_URL % [r.farm, r.server, r.id, r.secret, '_c', 'jpg'] end
    def url_h(r); PHOTO_SOURCE_URL % [r.farm, r.server, r.id, r.secret, '_h', 'jpg'] end
    def url_k(r); PHOTO_SOURCE_URL % [r.farm, r.server, r.id, r.secret, '_k', 'jpg'] end
    def url_o(r); PHOTO_SOURCE_URL % [r.farm, r.server, r.id, r.originalsecret, '_o', r.originalformat] end
    def url_profile(r); URL_PROFILE + (r.owner.respond_to?(:nsid) ? r.owner.nsid : r.owner) + '/' end
    def url_photopage(r); url_photostream(r) + r.id end
    def url_photosets(r); url_photostream(r) + 'sets/' end
    def url_photoset(r); url_photosets(r) + r.id end
    def url_short(r); URL_SHORT + base58(r.id) end
    def url_short_m(r); URL_SHORT + 'img/' + base58(r.id) + '_m.jpg' end
    def url_short_s(r); URL_SHORT + 'img/' + base58(r.id) + '.jpg' end
    def url_short_t(r); URL_SHORT + 'img/' + base58(r.id) + '_t.jpg' end
    def url_short_q(r); URL_SHORT + 'img/' + base58(r.id) + '_q.jpg' end
    def url_short_n(r); URL_SHORT + 'img/' + base58(r.id) + '_n.jpg' end
    def url_photostream(r)
      URL_PHOTOSTREAM +
        if r.respond_to?(:pathalias) && r.pathalias
          r.pathalias
        elsif r.owner.respond_to?(:nsid)
          r.owner.nsid
        else
          r.owner
        end + '/'
    end
  end

  self.check_certificate = true

end
