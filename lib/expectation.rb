#--
# Author::    radiospiel  (mailto:eno@radiospiel.org)
# Copyright:: Copyright (c) 2011, 2012 radiospiel
# License::   Distributes under the terms of the Modified BSD License, see LICENSE.BSD for details.
#++
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
  class MismatchError < ArgumentError
    attr :value, :expectation, :info

    def initialize(value, expectation, info = nil)
      @value, @expectation, @info = value, expectation, info
    end
    
    def to_s
      msg = "#{value.inspect} does not match #{expectation.inspect}"
      msg += ", #{info}" if info
      msg
    end
  end

  #
  # Verifies a number of expectations. If one or more expectations are 
  # not met it raises an ArgumentError. This method cannot be disabled.
  def expect!(*expectations, &block)
    STDERR.puts "*** expect! #{expectations.inspect}"
    
    expectations.each do |expectation|
      if expectation.is_a?(Hash)
        match! expectation, :__hash
      else
        match! expectation, :truish
      end
    end

    match! block, :__block if block
  end  

  # Matches a value against an expectation. Returns true or false.
  def match?(value, expectation)
    STDERR.puts "*** match? #{value.inspect} vs #{expectation.inspect}"
    
    match = case expectation
      when :truish  then !!value
      when :fail    then false
      when Array    then expectation.any? { |e| match?(value, e) }
      when Proc     then expectation.arity == 0 ? expectation.call : expectation.call(value)
      when Regexp   then value.is_a?(String) && expectation =~ value
      when :__block then
        value.call
      when :__hash  then
        STDERR.puts "*** match hash: #{value.inspect}"
        value.all? do |actual, exp|
          match? actual, exp
        end
      else          
        STDERR.puts "*** unspecified match? #{value.inspect} vs #{expectation.inspect}"
        expectation === value
    end
    
    STDERR.puts "!!! match? #{value.inspect} vs #{expectation.inspect}: #{match.inspect}"
    !! match
  end
  
  def match!(value, expectation) #:nodoc:#
    STDERR.puts "*** match! #{expectation.inspect} vs #{value.inspect}"

    return if match? value, expectation
    raise MismatchError, value, expectation
  end
end

Object.send :include, Expectation
