# Author::    radiospiel  (mailto:eno@radiospiel.org)
# Copyright:: Copyright (c) 2011, 2012 radiospiel
# License::   Distributes under the terms  of the Modified BSD License, see LICENSE.BSD for details.
require_relative 'test_helper'

class AssertionsTest < Test::Unit::TestCase
  include Expectation::Assertions

  def test_expectations
    expect! 1 => 1
    inexpect! 1 => 2
  end
end
