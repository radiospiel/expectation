require 'rubygems'
require 'bundler/setup'

require 'simplecov'
require 'test/unit'
require 'test/unit/ui/console/testrunner'

class Test::Unit::UI::Console::TestRunner
  def guess_color_availability; true; end
end

require 'mocha'

SimpleCov.start do
  add_filter "test/*.rb"
end

require "expectation"
