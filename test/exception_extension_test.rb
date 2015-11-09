# Author::    radiospiel  (mailto:eno@radiospiel.org)
# Copyright:: Copyright (c) 2011, 2012 radiospiel
# License::   Distributes under the terms  of the Modified BSD License, see LICENSE.BSD for details.
require_relative 'test_helper'

class ExpensionExtensionTest < Test::Unit::TestCase
  # Verify that the exception's backtrace is properly adjusted,
  # i.e. points to this file.
  def test_expectations_backtrace
    backtrace = nil

    begin
      expect! 1 => 0
    rescue
      backtrace = $!.backtrace
    end
    assert backtrace.first.include?("/exception_extension_test.rb:")
  end
end
