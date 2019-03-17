$:.push File.expand_path("../lib", __FILE__)
require 'flickr/version'

Gem::Specification.new do |s|
  s.name     = "flickr"
  s.summary  = "Flickr (formerly FlickRaw) is full-featured client for the Flickr API"
  s.authors  = ["Mael Clerambault", "Aidan Samuel"]
  s.email    = "mael@clerambault.fr"
  s.license  = "MIT"
  s.version  = Flickr::VERSION
  s.files    = Dir["examples/*.rb"] + Dir["test/*.rb"] + Dir["lib/**/*.rb"] + %w{flickr_rdoc.rb LICENSE CHANGELOG.md README.rdoc rakefile}

  s.metadata = {
    "bug_tracker_uri"   => "https://github.com/hanklords/flickraw/issues",
    "changelog_uri"     => "https://github.com/hanklords/flickraw/blob/master/CHANGELOG.md",
    "documentation_uri" => "https://github.com/hanklords/flickraw/blob/V2.0.1/README.rdoc",
    "homepage_uri"      => "https://github.com/hanklords/flickraw",
    "source_code_uri"   => "https://github.com/hanklords/flickraw",
  }

  s.add_development_dependency "rake", "~> 12.0"
  s.add_development_dependency "pry", "~> 0.11"
  s.add_development_dependency "nokogiri", "~> 1.0"

  s.required_ruby_version = '>= 2.3'

end
