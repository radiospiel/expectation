# Author::    radiospiel  (mailto:eno@radiospiel.org)
# Copyright:: Copyright (c) 2011, 2012 radiospiel
# License::   Distributes under the terms  of the Modified BSD License, see LICENSE.BSD for details.
require_relative 'test_helper'

class ExpectationTest < Test::Unit::TestCase
  def test_expectation_inherits_argument_error
    assert Expectation::Error < ArgumentError
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

  def test_array_expectations
    assert_expectation! 1 => [Fixnum, String]
    assert_expectation! 1 => [String, Fixnum]
    assert_failed_expectation! 1 => [NilClass, String]
  end

  def test_multi_expectations
    assert_expectation! 1 => Fixnum | String
    assert_expectation! 1 => String | 1
    assert_failed_expectation! 1 => NilClass | String
    assert_expectation! 1 => NilClass | String | 1
  end

  def test_exception_message
    e = assert_failed_expectation!({ 1 => 2 })
    assert e.message.include?("1 does not match 2")

    e = assert_failed_expectation!({ a: { b: "c" }} => { a: { b: "d" }})
    assert e.message.include?("\"c\" does not match \"d\", at key :b")
  end
end
