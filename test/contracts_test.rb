# Author::    radiospiel  (mailto:eno@radiospiel.org)
# Copyright:: Copyright (c) 2011, 2012 radiospiel
# License::   Distributes under the terms  of the Modified BSD License, see LICENSE.BSD for details.
require_relative 'test_helper'

class AnnotationsTest < Test::Unit::TestCase
  class Foo
    enable_annotations!

    +Expects(a: 1)
    def sum(a, b, c)
      a + b + c
    end

    +Returns(2)
    def returns_arg(r)
      r
    end
  end

  attr :foo
  
  def setup
    @foo = Foo.new
  end

  def test_annotations_check_number_of_arguments
    e = assert_raise(ArgumentError) {
      foo.sum(1)        # scripts/test:67:in `f': wrong number of arguments (1 for 3) (ArgumentError)
    }
    assert e.backtrace.first.include?("test/annotations_test.rb:")
  end

  def test_expects_annotation
    rv = nil
    assert_nothing_raised() { rv = foo.sum(1,2,3) }
    assert_equal(rv, 6)

    e = assert_raise(ArgumentError) {  
      foo.sum(2,2,3)
    }
    assert e.backtrace.first.include?("test/annotations_test.rb:")
  end

  def test_returns_annotation
    assert_nothing_raised() {
      foo.returns_arg(2)
    }

    e = assert_raise(ArgumentError) {
      foo.returns_arg(1)
    }
    assert e.backtrace.first.include?("test/annotations_test.rb:")
  end
end
