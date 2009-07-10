# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{flickraw}
  s.version = "0.6.1"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Mael Clerambault"]
  s.date = %q{2009-07-06}
  s.email = %q{maelclerambault@yahoo.fr}
  s.files = ["lib/flickraw.rb", "flickraw_rdoc.rb", "LICENSE", "README.rdoc", "rakefile", "examples/flickr_KDE.rb", "examples/upload.rb", "examples/auth.rb", "examples/interestingness.rb", "test/test.rb"]
  s.homepage = %q{http://hanklords.github.com/flickraw/}
  s.require_paths = ["lib"]
  s.required_ruby_version = Gem::Requirement.new(">= 1.8")
  s.rubyforge_project = %q{flickraw}
  s.rubygems_version = %q{1.3.1}
  s.summary = %q{Flickr library with a syntax close to the syntax described on http://www.flickr.com/services/api}

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 2

    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
    else
    end
  else
  end
end
