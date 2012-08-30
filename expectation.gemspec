$:.unshift File.expand_path("../lib", __FILE__)
require "expectation/version"

Gem::Specification.new do |gem|
  gem.name     = "expectation"
  gem.version  = Expectation::VERSION

  gem.author   = "radiospiel"
  gem.email    = "eno@radiospiel.org"
  gem.homepage = "http://github.com/radiospiel/expectation"
  gem.summary  = "Defensive programming with expectations"

  gem.description = gem.summary

  gem.files = Dir["**/*"].select { |d| d =~ %r{^(README|bin/|data/|ext/|lib/|spec/|test/)} }
end
