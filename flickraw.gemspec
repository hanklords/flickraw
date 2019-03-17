# -*- encoding: utf-8 -*-

lib = File.expand_path('../lib/', __FILE__)
$:.unshift lib unless $:.include?(lib)

require 'flickraw'

Gem::Specification.new do |s|
  s.summary = "Flickr library with a syntax close to the syntax described on http://www.flickr.com/services/api"
  s.name = "flickraw"
  s.author = "Mael Clerambault"
  s.email = "mael@clerambault.fr"
  s.homepage = "http://hanklords.github.com/flickraw/"
  s.license = "MIT"
  s.version = FlickRaw::VERSION
  s.files = Dir["examples/*.rb"] + Dir["test/*.rb"] + Dir["lib/**/*.rb"] + %w{flickraw_rdoc.rb LICENSE README.rdoc rakefile}
  s.post_install_message = <<~HEREDOC
  	DEPRECATION NOTICE: FlickRaw is now Flickr!

  	You are using FlickRaw (0.9.11) which is now deprecated.

  	Please upgrade to Flickr 2.x.x to get all the latest features and bug fixes.
  	Flickr 2.0.0 contains some breaking changes. Please read the upgrade notes.

  	Please use FlickRaw 0.9.10 if you don't want to see this message.

  HEREDOC
end
