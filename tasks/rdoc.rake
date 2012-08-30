$:.unshift File.expand_path("../lib", __FILE__)

require 'rdoc/task'

RDoc::Task.new do |rdoc|
  require "expectation/version"
  version = Expectation::VERSION

  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "expectation #{version}"
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end
