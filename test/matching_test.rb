# Author::    radiospiel  (mailto:eno@radiospiel.org)
# Copyright:: Copyright (c) 2011, 2012 radiospiel
# License::   Distributes under the terms  of the Modified BSD License, see LICENSE.BSD for details.
require_relative 'test_helper'

class MatchingTest < Test::Unit::TestCase
  def assert_match(value, expectation)
    assert_equal true, Expectation.match?(value, expectation)
  end

  def assert_mismatch(value, expectation)
    assert_equal false, Expectation.match?(value, expectation)
  end

  def test_mismatches_raise_exceptions
    assert_nothing_raised do
      Expectation.match! 1, 1
    end

    assert_raise(Expectation::Error) {
      Expectation.match! 1, 2
    }
  end

  def test_array_matches
    assert_nothing_raised do
      Expectation.match! [1], [Integer]
    end
    assert_raise(Expectation::Error) do
      Expectation.match! [1], [String]
    end

    # match: each entry is either Integer or String
    assert_nothing_raised do
      Expectation.match! [1, "2"], [[Integer, String]]
    end

    # fails: the 3rd entry is neither Integer nor String
    assert_raise(Expectation::Error) do
      Expectation.match! [1, "2", /abc/], [[Integer, String]]
    end
  end

  def test_int_expectations
    assert_match 1, 1
    assert_match 1, Fixnum
    assert_match 1, Integer
    assert_match 1, 0..2
    assert_match 1, 0..1
    assert_match 1, 1..10
    assert_match 1, [0,1,2]

    assert_mismatch 1, 2
    assert_mismatch 1, Float
    assert_mismatch 1, 0...1
    assert_mismatch 1, 3..5
    assert_mismatch 1, [3,4,5]
  end

  def test_lambda_expectations
    # passes in value?
    assert_match 1, lambda { |i| i.odd? }
    assert_mismatch 1, lambda { |i| i.even? }

    # does not pass in a value
    r = false
    assert_mismatch 1, lambda { r }

    r = true
    assert_match 1, lambda { r }
  end

  def test_regexp_expectations
    assert_match    " foo", /foo/
    assert_mismatch " foo", /^foo/

    assert_match    "1", /1/
    assert_mismatch "1", /2/

    assert_mismatch 1, /1/
    assert_mismatch 1, /2/
  end

  def test_hash_expectations
    assert_mismatch({}, { :key => "Foo" })
    assert_match({ :key => "Foo" }, { :key => "Foo" })

    assert_mismatch({ :other_key => "Foo" }, { :key => "Foo" })
    assert_mismatch({ :key => "Bar" }, { :key => "Foo" })

    assert_match({ :key => "Foo" }, { :key => String })
    assert_match({ :key => "Foo" }, { :key => [Integer,String] })
    assert_mismatch({ :key => "Foo" }, { :key => [Integer,"Bar"] })
    assert_match({ :other_key => "Foo" }, { :key => [nil, "Foo"] })
  end
end
