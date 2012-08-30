$:.unshift File.expand_path("../lib", __FILE__)

require 'rdoc/task'

RDoc::Task.new do |rdoc|
  require "expectations/version"
  version = Expectations::VERSION

  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "expectations #{version}"
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end
