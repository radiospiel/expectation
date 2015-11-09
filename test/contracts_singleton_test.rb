# Author::    radiospiel  (mailto:eno@radiospiel.org)
# Copyright:: Copyright (c) 2011, 2012 radiospiel
# License::   Distributes under the terms  of the Modified BSD License, see LICENSE.BSD for details.
require_relative 'test_helper'

require "contracts"

class ContractsSingletonTest < Test::Unit::TestCase
  class Foo
    include Contracts

    +Expects(one: 1)
    def self.klass_method(one)
      one * 2
    end
  end

  def test_class_method
    assert_nothing_raised() {
      Foo.klass_method(1)
    }

    e = assert_raise(Contracts::Error) {
      Foo.klass_method(2)
    }
    assert e.backtrace.first.include?("test/contracts_singleton_test.rb:")
  end
end
