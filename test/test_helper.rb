require 'rubygems'
require 'bundler/setup'

if ENV["COVERAGE"]
  require 'simplecov'
  require 'simplecov-console'
end

require 'test/unit'

if ENV["COVERAGE"]
  SimpleCov.start do
    add_filter "test/*.rb"
  end

  SimpleCov.formatter = SimpleCov::Formatter::MultiFormatter[
    SimpleCov::Formatter::HTMLFormatter,
    SimpleCov::Formatter::Console,
  ]
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
