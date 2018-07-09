require 'json'
require 'flickraw/version'
require 'flickraw/util'
require 'flickraw/error'
require 'flickraw/oauth'
require 'flickraw/request'
require 'flickraw/response'
require 'flickraw/api'

module FlickRaw
  USER_AGENT = "FlickRaw/#{VERSION}"

  self.check_certificate = true
end
