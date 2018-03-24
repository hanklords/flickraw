require 'json'
require 'flickraw/util'
require 'flickraw/error'
require 'flickraw/oauth'
require 'flickraw/request'
require 'flickraw/response'
require 'flickraw/api'
require 'flickraw/helper'

module FlickRaw
  VERSION='0.9.9'
  USER_AGENT = "FlickRaw/#{VERSION}"

  self.secure = true
  self.check_certificate = true
end

