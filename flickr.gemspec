$:.push File.expand_path("../lib", __FILE__)
require 'flickr/version'

Gem::Specification.new do |s|
  s.name     = "flickr"
  s.summary  = "Flickr library with a syntax close to the syntax described on https://www.flickr.com/services/api"
  s.author   = "Mael Clerambault"
  s.email    = "mael@clerambault.fr"
  s.homepage = "https://hanklords.github.io/flickraw/"
  s.license  = "MIT"
  s.version  = Flickr::VERSION
  s.files    = Dir["examples/*.rb"] + Dir["test/*.rb"] + Dir["lib/**/*.rb"] + %w{flickr_rdoc.rb LICENSE README.rdoc rakefile}

  s.add_development_dependency "rake", "~> 12.0"
  s.add_development_dependency "pry", "~> 0.11"
  s.add_development_dependency "nokogiri", "~> 1.0"

  s.required_ruby_version = '>= 2.3'

end
