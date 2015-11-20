$:.unshift File.expand_path("../lib", __FILE__)

require "bundler/setup"

Dir[File.expand_path("../tasks/*.rake", __FILE__)].each do |task|
  load task
end

# Add "rake release and rake install"
Bundler::GemHelper.install_tasks

task :coverage do
  system "COVERAGE=1 rake test"
end

task :default => [:test, :coverage]
