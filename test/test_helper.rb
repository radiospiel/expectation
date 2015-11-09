require 'rubygems'
require 'bundler/setup'

require 'simplecov'
require 'test/unit'
require 'test/unit/ui/console/testrunner'

class Test::Unit::UI::Console::TestRunner
  def guess_color_availability; true; end
end

require 'mocha/setup'

SimpleCov.start do
  add_filter "test/*.rb"
end

require "expectation"

class Test::Unit::TestCase
  def assert_expectation!(*expectation, &block)
    assert_nothing_raised do
      expect! *expectation, &block
    end
  end

  def assert_failed_expectation!(*expectation, &block)
    assert_raise(Expectation::Error) {
      expect! *expectation, &block
    }
  end
end
