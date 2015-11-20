# Author::    radiospiel  (mailto:eno@radiospiel.org)
# Copyright:: Copyright (c) 2011, 2012 radiospiel
# License::   Distributes under the terms  of the Modified BSD License, see LICENSE.BSD for details.
require_relative 'test_helper'

require "contracts"
Contracts.logger.level = Logger::ERROR

class ContractsTest < Test::Unit::TestCase
  class Base
    attr :checked

    def check
      @checked = true
    end
  end

  class Foo < Base
    include Contracts

    +Expects(a: 1)
    def sum(a, b, c)
      a + b + c
    end

    +Returns(2)
    def returns_arg(r)
      r
    end

    +Expects(v: Fixnum)
    def throw_on_one(v)
      raise if v == 1
    end

    +Nothrow()
    def unexpected_throw_on_one(v)
      raise if v == 1
    end

    +Returns(true)
    def check
      super
    end
  end

  attr :foo

  def setup
    @foo = Foo.new
  end

  def test_contracts_check_number_of_arguments
    e = assert_raise(ArgumentError) {
      foo.sum(1)        # scripts/test:67:in `f': wrong number of arguments (1 for 3) (ArgumentError)
    }
    assert e.backtrace.first.include?("test/contracts_test.rb:")
  end

  def test_expects_contract
    rv = nil
    assert_nothing_raised() { rv = foo.sum(1,2,3) }
    assert_equal(rv, 6)

    e = assert_raise(Contracts::Error) {
      foo.sum(2,2,3)
    }
    assert e.backtrace.first.include?("test/contracts_test.rb:")
  end

  def test_returns_contract
    assert_nothing_raised() {
      foo.returns_arg(2)
    }

    e = assert_raise(Contracts::Error) {
      foo.returns_arg(1)
    }
    assert e.backtrace.first.include?("test/contracts_test.rb:")
  end

  def test_calls_super
    foo.check
    assert foo.checked
  end

  def test_nothrow_contract
    assert_nothing_raised() {
      foo.unexpected_throw_on_one(2)
    }

    e = assert_raise(Contracts::Error) {
      foo.unexpected_throw_on_one(1)
    }
    assert e.backtrace.first.include?("test/contracts_test.rb:")
  end

  def test_still_throws_fine
    assert_nothing_raised() {
      foo.throw_on_one(2)
    }

    assert_raise(RuntimeError) {
      foo.throw_on_one(1)
    }
  end

  class Foo
    attr :a, :b
    +Expects(b: String)
    def with_default_arg(a, b="check")
      @a, @b = a, b
    end
  end

  def test_default_args
    foo.with_default_arg :one

    assert_equal(foo.a, :one)
    assert_equal(foo.b, "check")
  end

  require "timecop"
  class Foo
    +Runtime(0.01, max: 0.05)
    def wait_for(time)
      Timecop.travel(Time.now + time)
    end
  end

  def test_runtime
    foo.wait_for 0.001
    foo.wait_for 0.02

    e = assert_raise(Contracts::Error) {
      foo.wait_for 10
    }

    Timecop.return
  end
end
