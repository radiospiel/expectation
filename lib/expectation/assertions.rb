#--
# Author::    radiospiel  (mailto:eno@radiospiel.org)
# Copyright:: Copyright (c) 2011, 2012 radiospiel
# License::   Distributes under the terms of the Modified BSD License, see LICENSE.BSD for details.
#++
# By requiring "expectation/assertions" you add expect! und unexpect! assertions
# to your test/unit testcases.

if !defined?(::Expectation::Assertions)

if !defined?(::Expectation)
  require_relative "../expectation"
end

# The Expectation::Assertions module provides expect! and inexpect!
# assertions to use from within test cases.
#
# == Example
#
#   require_relative 'test_helper'
#   require 'expectation/assertions'
# 
#   class ExpectationTest < Test::Unit::TestCase
#     def test_one
#     end
#   end
#
module Expectation::Assertions
  alias_method :original_expect!, :expect! #:nodoc:

  def assert_expectation(should_succeed, *expectation, &block) #:nodoc:
    original_expect! *expectation, &block
    assert_block { should_succeed }
  rescue ArgumentError
    assert_block($!.to_s) { !should_succeed }
  end
  
  # verifies the passed in expectations
  def expect!(*expectation, &block)
    assert_expectation true, *expectation, &block
  end
  
  # verifies the failure of the passed in expectations
  def inexpect!(*expectation, &block)
    assert_expectation false, *expectation, &block
  end
end

end

if !defined?(Test::Unit)
  STDERR.puts "Please load 'test/unit' first"
end

class Test::Unit::TestCase
  include Expectation::Assertions
end
