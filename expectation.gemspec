Gem::Specification.new do |gem|
  gem.required_ruby_version = '~> 2.4'

  gem.name     = "expectation"
  gem.version  = File.read "VERSION"
  gem.author   = "radiospiel"
  gem.email    = "eno@radiospiel.org"
  gem.homepage = "http://github.com/radiospiel/expectation"
  gem.summary  = "Defensive programming with expectations"

  gem.description = gem.summary

  gem.files = Dir["**/*"].select { |d| d =~ %r{^(README|bin/|data/|ext/|lib/|spec/|test/)} }
end
