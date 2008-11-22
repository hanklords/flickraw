require 'rake/rdoctask'
require 'rake/packagetask'
require 'rake/gempackagetask'
require 'rake/testtask'

require 'lib/flickraw'
require 'flickraw_rdoc'

PKG_FILES = FileList["lib/flickraw.rb", "flickraw_rdoc.rb", "copying.txt", "README", "rakefile", "examples/*.rb", "test/*.rb"].to_a

spec = Gem::Specification.new do |s|
  s.summary = "Flickr library with a syntax close to the syntax described on http://www.flickr.com/services/api"
  s.name = "flickraw"
  s.author = "Mael Clerambault"
  s.email =  "maelclerambault@yahoo.fr"
  s.homepage = "http://flickraw.rubyforge.org"
  s.rubyforge_project = "flickraw"
  s.version = FlickRaw::VERSION
  s.files = PKG_FILES
  s.test_files = FileList["test/*.rb"].to_a
  s.add_dependency 'json'
end

Rake::RDocTask.new do |rd|
  rd.rdoc_files.include "README", "lib/flickraw.rb"
  rd.options << "--inline-source"
end

Rake::GemPackageTask.new spec do |p|
  p.need_tar_gz = true
end

Rake::TestTask.new
