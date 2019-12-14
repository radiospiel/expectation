# Author::    radiospiel  (mailto:eno@radiospiel.org)
# Copyright:: Copyright (c) 2011, 2012 radiospiel
# License::   Distributes under the terms  of the Modified BSD License, see LICENSE.BSD for details.
require_relative 'test_helper'

class VersionTest < Test::Unit::TestCase
  def test_returns_a_version
    assert_match(/\d\.\d\.\d/,Expectation::VERSION)
  end
end
