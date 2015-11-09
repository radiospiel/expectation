# Author::    radiospiel  (mailto:eno@radiospiel.org)
# Copyright:: Copyright (c) 2011, 2012 radiospiel
# License::   Distributes under the terms  of the Modified BSD License, see LICENSE.BSD for details.
require_relative 'test_helper'

class AnnotationsTest < Test::Unit::TestCase
  class Foo
    enable_annotations!

    expects! a: 1
    def f(a, b, c)
      [ a, b, c]
    end

    returns! 2
    def g(r)
      r
    end
  end

  attr :foo
  
  def setup
    @foo = Foo.new
  end

  def test_annotations_check_number_of_arguments
    e = assert_raise(ArgumentError) {  
      foo.f(1)        # scripts/test:67:in `f': wrong number of arguments (1 for 3) (ArgumentError)
    }
    assert e.backtrace.first.include?("test/annotations_test.rb:")
  end

  def test_expects_annotation
    assert_nothing_raised() { 
      foo.f(1,2,3)
    }

    e = assert_raise(Expectation::Error) {  
      foo.f(2,2,3)
    }
    assert e.backtrace.first.include?("test/annotations_test.rb:")
  end

  def test_returns_annotation
    assert_nothing_raised() {  
      foo.g(2)
    }

    e = assert_raise(Expectation::Error) {  
      foo.g(1)
    }
    assert e.backtrace.first.include?("test/annotations_test.rb:")
  end
end
