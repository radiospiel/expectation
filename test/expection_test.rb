# Author::    radiospiel  (mailto:eno@radiospiel.org)
# Copyright:: Copyright (c) 2011, 2012 radiospiel
# License::   Distributes under the terms  of the Modified BSD License, see LICENSE.BSD for details.
require_relative 'test_helper'

class ExpectationTest < Test::Unit::TestCase
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

  #
  # This test covers the usual use case: expectations are 
  # passed in a single Hash.
  def test_hash_expectation
    assert_expectation! "1" => /1/
    assert_failed_expectation! "1" => /2/

    assert_expectation! 1 => 1, :a => :a
    assert_failed_expectation! 1 => 2, :a => :a
  end

  def test_simple_expectations
    assert_expectation! "1" => /1/
    assert_expectation! 1, 1, 1, /1/
    assert_expectation! 1, 1, "1" => /1/

    assert_failed_expectation! 1, 1, "1" => /2/
    assert_failed_expectation! 1, 1, 1 => /2/
    assert_failed_expectation! 1, nil, "1" => /1/
    assert_failed_expectation! 1, false, "1" => /1/
  end

  def test_block_expectations
    assert_expectation! do true end
    assert_failed_expectation! do false end
    assert_failed_expectation! do nil end
  end
end
