#--
# Author::    radiospiel  (mailto:eno@radiospiel.org)
# Copyright:: Copyright (c) 2011, 2012 radiospiel
# License::   Distributes under the terms of the Modified BSD License, see LICENSE.BSD for details.
#++

module Expectation; end

require_relative "core/exception"
require_relative "expectation/matcher"
require_relative "expectation/assertions"

# The Expectation module implements methods to verify one or more values
# against  set of expectations. This is a subset of
# design-by-contract programming (see http://en.wikipedia.org/wiki/Design_by_contract)
# features, and should speed you up during development phases.
#
# == Example
#
# This function expects a String argument starting with <tt>"http:"</tt>, 
# an Integer or Float argument, and a Hash with a String entry at key 
# <tt>:foo</tt>, and either an Array or +nil+ at key <tt>:bar</tt>.
# 
#   def function(a, b, options = {})
#     expect! a => /^http:/, 
#             b => [Integer, Float], 
#             options => {
#               :foo => String,
#               :bar => [ Array, nil ]
#             }
#   end

module Expectation
  Error = Expectation::Matcher::Mismatch

  #
  # Verifies a number of expectations. If one or more expectations are 
  # not met it raises an Error (on the first failing expectation).
  #
  # In contrast to the global expect! function this method does not
  # adjust an Error's backtrace.
  def self.expect!(*expectations, &block)
    expectations.each do |expectation|
      if expectation.is_a?(Hash)
        expectation.all? do |actual, exp|
          Matcher.match! actual, exp
        end
      else
        Matcher.match! expectation, :truish
      end
    end

    Matcher.match! block, :__block if block
  end
end

def expect!(*args, &block)
  Expectation.expect! *args, &block
rescue Expectation::Error
  $!.reraise_with_current_backtrace!
end
