#--
# Author::    radiospiel  (mailto:eno@radiospiel.org)
# Copyright:: Copyright (c) 2011, 2012 radiospiel
# License::   Distributes under the terms of the Modified BSD License, see LICENSE.BSD for details.
#++

module Expectation; end

require_relative "core/exception"
require_relative "expectation/annotations"
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
  class Error < ArgumentError
    attr :value, :expectation, :info

    def initialize(value, expectation, info = nil)
      @value, @expectation, @info = 
        value, expectation, info
    end
    
    def to_s
      message = "#{value.inspect} does not match #{expectation.inspect}"
      message += ", #{info}" if info
      message
    end
  end

  #
  # Verifies a number of expectations. If one or more expectations are 
  # not met it raises an ArgumentError (on the first failing expectation).
  def expect!(*expectations, &block)
    expectations.each do |expectation|
      if expectation.is_a?(Hash)
        expectation.all? do |actual, exp|
          _match! actual, exp
        end
      else
        _match! expectation, :truish
      end
    end

    _match! block, :__block if block
  rescue Error
    $!.reraise_with_current_backtrace!
  end  

  #
  # Does a value match an expectation?
  def match?(value, expectation)
    _match! value, expectation
    true
  rescue Error
    false
  end

  private

  # Matches a value against an expectation. Raises an Expectation::Error
  # if the expectation could not be matched. Returns true if there is a match.
  def _match!(value, expectation)
    match = case expectation
      when :truish  then !!value
      when :fail    then false
      when Array    then expectation.any? { |e| _match?(value, e) }
      when Proc     then expectation.arity == 0 ? expectation.call : expectation.call(value)
      when Regexp   then value.is_a?(String) && expectation =~ value
      when :__block then value.call
      when Hash  then
        Hash === value && begin
          expectation.all? do |key, exp|
            _match? value[key], exp
          end
        end
      else
        expectation === value
    end

    return true if match

    raise Error.new(value, expectation)
  end

  def _match?(value, expectation)
    _match! value, expectation
    true
  rescue Error
    false
  end
end

Object.send :include, Expectation
