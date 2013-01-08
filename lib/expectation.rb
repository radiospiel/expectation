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
  def self.timeout=(timeout)
    Thread.current[:expectation_timeout] = timeout
  end

  def self.timeout
    Thread.current[:expectation_timeout]
  end
  
  # Verifies a number of expectations. Raises an ArgumentError if one
  # or more expectations are not met.
  #
  # In contrast to Expectation#expect this method can not be
  # disabled at runtime.
  def expect!(*expectations, &block)
    if block_given? && Expectation.timeout
      timeout, Expectation.timeout = Expectation.timeout, nil
      begin
        (timeout / 0.05).to_i.times do
          begin
            expect! *expectations, &block
            return
          rescue ArgumentError
          end
          Thread.send :sleep, 0.05
        end
      ensure
        Expectation.timeout = timeout
      end
    end

    if block_given?
      Expectation.verify! true, block
    end
    
    expectations.each do |expectation|
      case expectation
      when Hash
        expectation.each do |value, e|
          Expectation.verify! value, e
        end
      else
        Expectation.verify! expectation, :truish
      end
    end
  end

  # Verifies a number of expectations. If one or more expectations are 
  # not met it raises an ArgumentError.
  #
  # This method can be enabled or disabled at runtime using 
  # Expectation.enable and Expectation.disable.  
  def expect(*expectations, &block)
    expect!(*expectations, &block)
  end
  
  # A do nothing expect method. This is the standin for expect, when
  # Expectation are disabled.
  def expect_dummy!(*expectations, &block) #:nodoc:
  end
  
  # Does a value meet the expectation? Retruns +true+ or +false+. 
  def self.met?(value, expectation) #:nodoc:
    case expectation
    when :truish  then !!value
    when :fail    then false
    when Array    then expectation.any? { |e| met?(value, e) }
    when Proc     then expectation.arity == 0 ? expectation.call : expectation.call(value)
    when Regexp   then value.is_a?(String) && expectation =~ value
    else          expectation === value
    end
  end

  # Verifies a value against an expectation. Builds and raises
  # an ArgumentError exception if the expectation is not met.
  def self.verify!(value, expectation)
    failed_value, failed_expectation, message = value, expectation, nil
    
    # Test expectation, collect failed_value, failed_expectation, failed_message
    unless expectation.is_a?(Hash)
      good = met?(value, expectation)
    else
      good = met?(value, Hash)
      if good
        good = expectation.all? do |key, expect|
          next true if met?(value[key], expect)
          
          failed_value, failed_expectation, message = value[key], expect, "at key #{key.inspect}"
          false
        end
      end
    end
    
    # are we good?
    return if good

    # build exception with adjusted backtrace.
    backtrace = caller[5 .. -1]
    
    e = ArgumentError.new "#{failed_value.inspect} does not meet expectation #{failed_expectation.inspect}#{message && ", #{message}"}"
    e.singleton_class.send(:define_method, :backtrace) do
      backtrace
    end
    raise e
  end

  # Enable the Expectation#expect method.
  def self.enable
    alias_method :expect, :expect!
  end

  # Disable the Expectation#expect method.
  def self.disable
    alias_method :expect, :expect_dummy!
  end
end

Expectation.enable
Object.send :include, Expectation
