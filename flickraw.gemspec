# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{flickraw}
  s.version = "0.8.3"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Mael Clerambault"]
  s.date = %q{2010-11-22}
  s.email = %q{maelclerambault@yahoo.fr}
  s.files = ["lib/flickraw.rb", "flickraw_rdoc.rb", "LICENSE", "README.rdoc", "rakefile", "examples/flickr_KDE.rb", "examples/auth.rb", "examples/interestingness.rb", "examples/upload.rb", "test/test_upload.rb", "test/test.rb"]
  s.homepage = %q{http://hanklords.github.com/flickraw/}
  s.require_paths = ["lib"]
  s.rubygems_version = %q{1.3.7}
  s.summary = %q{Flickr library with a syntax close to the syntax described on http://www.flickr.com/services/api}

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<json>, [">= 1.1.1"])
    else
      s.add_dependency(%q<json>, [">= 1.1.1"])
    end
  else
    s.add_dependency(%q<json>, [">= 1.1.1"])
  end
end
