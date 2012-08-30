$:.unshift File.expand_path("../lib", __FILE__)
require "expectations/version"

Gem::Specification.new do |gem|
  gem.name     = "expectations"
  gem.version  = Expectations::VERSION

  gem.author   = "radiospiel"
  gem.email    = "eno@radiospiel.org"
  gem.homepage = "http://github.com/radiospiel/expectations"
  gem.summary  = "Defensive programming with expectations"

  gem.description = gem.summary

  gem.files = Dir["**/*"].select { |d| d =~ %r{^(README|bin/|data/|ext/|lib/|spec/|test/)} }
end
