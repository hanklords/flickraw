#!/usr/bin/env ruby

require 'webrick'

server = WEBrick::HTTPServer.new :Port => 9900
server.mount '/', WEBrick::HTTPServlet::FileHandler, File.join(File.dirname(__FILE__), '/')
trap('INT') { server.stop }
server.start
