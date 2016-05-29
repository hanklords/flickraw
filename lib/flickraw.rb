require 'json'
require 'flickraw/error'
require 'flickraw/oauth'
require 'flickraw/request'
require 'flickraw/response'
require 'flickraw/api'
require 'flickraw/helper'

module FlickRaw
  VERSION='0.9.8'
  USER_AGENT = "FlickRaw/#{VERSION}"
  
  self.secure = true
  self.check_certificate = true
end

