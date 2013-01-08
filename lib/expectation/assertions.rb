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
  # verifies the passed in expectations
  def expect!(*expectation, &block)
    good = Expectation.met_expectations?(*expectation, &block)
    assert_block(Expectation.last_error) { good }
  end
  
  # verifies the failure of the passed in expectations
  def inexpect!(*expectation, &block)
    good = Expectation.met_expectations?(*expectation, &block)
    assert_block("Expectation(s) should fail, but didn't") { !good }
  end
end

end

if !defined?(Test::Unit)
  STDERR.puts "Please load 'test/unit' first"
end

class Test::Unit::TestCase
  include Expectation::Assertions
end
