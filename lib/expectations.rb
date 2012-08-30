# Author::    radiospiel  (mailto:eno@radiospiel.org)
# Copyright:: Copyright (c) 2011, 2012 radiospiel
# License::   Distributes under the terms of the Modified BSD License, see LICENSE.BSD for details.
module Expectations
  def real_expect!(*expectations, &block)
    if block_given?
      Expectations.verify! true, block
    end
    
    expectations.each do |expectation|
      case expectation
      when Hash
        expectation.each do |value, e|
          Expectations.verify! value, e
        end
      else
        Expectations.verify! expectation, :truish
      end
    end
  end

  def dummy_expect!(*expectations, &block)
  end
  
  def self.met?(value, expectation)
    case expectation
    when :truish  then !!value
    when :fail    then false
    when Array    then expectation.any? { |e| met?(value, e) }
    when Proc     then expectation.arity == 0 ? expectation.call : expectation.call(value)
    when Regexp   then value.is_a?(String) && expectation =~ value
    else          expectation === value
    end
  end

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

  def self.enable
    alias_method :expect!, :real_expect!
  end
  
  def self.disable
    alias_method :expect!, :dummy_expect!
  end
end

Expectations.enable
Object.send :include, Expectations
