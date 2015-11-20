#--
# Author::    radiospiel  (mailto:eno@radiospiel.org)
# Copyright:: Copyright (c) 2011, 2012 radiospiel
# License::   Distributes under the terms of the Modified BSD License,
#             see LICENSE.BSD for details.
#++


# The Expectation::Assertions module provides expect! and inexpect!
# assertions to use from within test cases.
#
# == Example
#
#   class ExpectationTest < Test::Unit::TestCase
#     include Expectation::Assertions
#
#     def test_one
#     end
#   end
#
module Expectation::Assertions
  # verifies the passed in expectations
  def expect!(*expectation, &block)
    exc = nil

    begin
      Expectation.expect!(*expectation, &block)
    rescue Expectation::Error
      exc = $!
    end

    assert_block(exc && exc.message) { !exc }
  end

  # verifies the failure of the passed in expectations
  def inexpect!(*expectation, &block)
    exc = nil

    begin
      Expectation.expect!(*expectation, &block)
    rescue Expectation::Error
      exc = $!
    end

    assert_block("Expectation(s) should fail, but didn't") { exc }
  end
end
