# Author::    radiospiel  (mailto:eno@radiospiel.org)
# Copyright:: Copyright (c) 2011, 2012 radiospiel
# License::   Distributes under the terms  of the Modified BSD License, see LICENSE.BSD for details.
require_relative 'test_helper'

require "contracts"

class ContractsModuleTest < Test::Unit::TestCase
  module M
    include Contracts

    +Expects(one: 1)
    def needs_one(one)
      one * 2
    end
  end

  class Klass
    extend M
  end

  class Instance
    include M
  end

  def test_class_method
    assert_nothing_raised() {
      Klass.needs_one(1)
    }

    e = assert_raise(Contracts::Error) {
      Klass.needs_one(2)
    }
    assert e.backtrace.first.include?("test/contracts_module_test.rb:")
  end

  def test_instance_method
    instance = Instance.new
    assert_nothing_raised() {
      instance.needs_one(1)
    }

    e = assert_raise(Contracts::Error) {
      instance.needs_one(2)
    }
    assert e.backtrace.first.include?("test/contracts_module_test.rb:")
  end
end
