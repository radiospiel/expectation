# Author::    radiospiel  (mailto:eno@radiospiel.org)
# Copyright:: Copyright (c) 2011, 2012 radiospiel
# License::   Distributes under the terms  of the Modified BSD License, see LICENSE.BSD for details.
require_relative 'test_helper'
require "expectation/assertions"

class AssertionsTest < Test::Unit::TestCase
  def test_expectations
    expect! 1 => 1
    inexpect! 1 => 2
  end
end
