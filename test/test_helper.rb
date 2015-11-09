require 'rubygems'
require 'bundler/setup'

require 'simplecov'
require 'simplecov-console'
require 'test/unit'

SimpleCov.start do
  add_filter "test/*.rb"
end

SimpleCov.formatter = SimpleCov::Formatter::MultiFormatter[
  SimpleCov::Formatter::HTMLFormatter,
  SimpleCov::Formatter::Console,
]

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
