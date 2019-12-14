$:.unshift File.expand_path("../lib", __FILE__)

require "bundler/setup"

Dir[File.expand_path("../tasks/*.rake", __FILE__)].each do |task|
  load task
end

task :coverage do
  system "COVERAGE=1 rake test"
end

task :default => [:test, :coverage]
