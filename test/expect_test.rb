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
    assert_raise(ArgumentError) {  
      expect! *expectation, &block
    }
  end

  def assert_expectation(*expectation, &block)
    assert_nothing_raised do
      expect *expectation, &block
    end
  end
  
  def assert_failed_expectation(*expectation, &block)
    assert_raise(ArgumentError) {  
      expect *expectation, &block
    }
  end
  
  # Verify that the exception's backtrace is properly adjusted,
  # i.e. points to this file.
  def test_expectations_backtrace
    backtrace = nil
    
    begin
      expect! 1 => 0
    rescue 
      backtrace = $!.backtrace
    end
    assert backtrace.first.include?("/expect_test.rb:")
  end
  
  def test_int_expectations
    assert_expectation! 1 => 1
    assert_expectation! 1 => Fixnum
    assert_expectation! 1 => Integer
    assert_expectation! 1 => 0..2
    assert_expectation! 1 => 0..1
    assert_expectation! 1 => 1..10
    assert_expectation! 1 => [0,1,2]
    assert_expectation! 1 => lambda { |i| i.odd? }

    assert_failed_expectation! 1 => 2
    assert_failed_expectation! 1 => Float
    assert_failed_expectation! 1 => 0...1
    assert_failed_expectation! 1 => 3..5
    assert_failed_expectation! 1 => [3,4,5]
    assert_failed_expectation! 1 => lambda { |i| i.even? }
  end
  
  def test_regexp_expectations
    assert_expectation! " foo" => /foo/
    assert_failed_expectation! " foo" => /^foo/

    assert_expectation! "1" => /1/
    assert_failed_expectation! "1" => /2/

    assert_failed_expectation! 1 => /1/
    assert_failed_expectation! 1 => /2/
  end
  
  def test_multiple_expectations
    assert_expectation! 1 => 1, :a => :a
    assert_failed_expectation! 1 => 2, :a => :a
  end

  def test_array_expectations
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

  def test_hash_expectations
    assert_failed_expectation!({} => { :key => "Foo" })
    assert_expectation!({ :key => "Foo" } => { :key => "Foo" })

    assert_failed_expectation!({ :other_key => "Foo" } => { :key => "Foo" })
    assert_failed_expectation!({ :key => "Bar" } => { :key => "Foo" })

    assert_expectation!({ :key => "Foo" } => { :key => String })
    assert_expectation!({ :key => "Foo" } => { :key => [Integer,String] })
    assert_failed_expectation!({ :key => "Foo" } => { :key => [Integer,"Bar"] })
    assert_expectation!({ :other_key => "Foo" } => { :key => [nil, "Foo"] })
  end
end
