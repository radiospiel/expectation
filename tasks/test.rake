require 'rake/testtask'

namespace :test do
  Rake::TestTask.new(:base) do |test|
    test.libs << 'lib' << 'test'
    test.pattern = 'test/**/expect_test.rb'
    test.verbose = true
  end

  Rake::TestTask.new(:unit) do |test|
    test.libs << 'lib' << 'test'
    test.pattern = 'test/**/assertions_test.rb'
    test.verbose = true
  end
end

task :test => [ "test:base", "test:unit" ] do
  STDERR.puts <<-STR

  ** TEST DONE. 

  Note the the coverage info in ./coverage is flaky when running all tests at once.
  Use 'rake test:base' or 'rake test:unit' to generate individual coverage information.
  
  STR
end