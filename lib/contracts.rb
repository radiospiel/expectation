#--
# Author::    radiospiel  (mailto:eno@radiospiel.org)
# Copyright:: Copyright (c) 2011, 2012 radiospiel
# License::   Distributes under the terms of the Modified BSD License, see LICENSE.BSD for details.
#++

# The Contract module provides annotation support. That basically
# means you can define expectations outside (or, to be more specific, before)
# the function definition.
#
# We currently support the following annotations:
#
# - expects!
# - returns!
#
# == Example
#
#   class Foo
#
#     +Expects(value1: Fixnum, value2: /.@./)
#     +Returns(Fixnum)
#
#     def bar(value1, value2)
#     end
#   end
#
module Contracts
  class Error < ArgumentError; end

  def self.current_contracts
    Thread.current[:current_contracts] ||= []
  end

  def self.consume_current_contracts
    r, Thread.current[:current_contracts] = Thread.current[:current_contracts], nil
    r
  end

  def self.included(klass)
    klass.extend ClassMethods
  end

  class AnnotatedMethod
    def initialize(method, annotations)
      @method = method

      @before_annotations     = annotations.select { |annotation| annotation.respond_to?(:before_call) }
      @after_annotations      = annotations.select { |annotation| annotation.respond_to?(:after_call) }
      @exception_annotations  = annotations.select { |annotation| annotation.respond_to?(:on_exception) }

      annotations.each do |annotation|
        annotation.method = method
      end
    end

    def invoke(receiver, *args, &blk)
      @before_annotations.each do |annotation|
        annotation.before_call(receiver, *args, &blk)
      end
 
      rv = @method.bind(receiver).call(*args, &blk)
 
      @after_annotations.each do |annotation|
        annotation.after_call(rv, receiver, *args, &blk)
      end
 
      return rv
    rescue StandardError => exc
      @exception_annotations.each do |annotation|
        annotation.on_exception(exc, receiver, *args, &blk)
      end
      raise exc
    end
  end

  module ClassMethods
    def method_added(name)
      # [fixme] call super
      return unless annotations = Contracts.consume_current_contracts

      method = instance_method(name)
      annotated_method = Contracts::AnnotatedMethod.new(method, annotations)

      define_method name do |*args, &blk|
        annotated_method.invoke self, *args, &blk
      end
    end
  end

  #
  # A Base contract.
  class Base
    #
    # This is the unary "+" operator. It adds the contract to the current_contracts array.
    def +@
      Contracts.current_contracts << self
    end

    #
    # contains the unbound method once the contract is initialized, which happens
    # in the Class#method_added callback.
    attr :method, true

    #
    # Returns a description of the method 
    def method_name
      "#{method.owner}##{method.name}"
    end
  end
end

require "expectation"

class Contracts::Expects < Contracts::Base
  attr :expectations

  def initialize(expectations)
    @expectations = expectations
  end

  def before_call(receiver, *args, &blk)
    @parameter_names ||= method.parameters.map(&:last)

    @parameter_names.each_with_index do |parameter_name, idx|
      next unless expectation = expectations[parameter_name]

      Expectation.match! args[idx], expectation
    end
  rescue Expectation::Error
    raise Contracts::Error, "#{$!} in call to `#{method_name}`", caller[5..-1]
  end
end

module Contracts::ClassMethods
  def Expects(expectation)
    expect! expectation => Hash
    Contracts::Expects.new(expectation)
  end
end

class Contracts::Returns < Contracts::Base
  attr :expectation

  def initialize(expectation)
    @expectation = expectation
  end

  def after_call(rv, receiver, *args, &blk)
    Expectation.match! rv, expectation
  rescue Expectation::Error
    raise Contracts::Error, "#{$!} in return of `#{method_name}`", caller[5..-1]
  end
end

module Contracts::ClassMethods
  def Returns(expectation)
    Contracts::Returns.new(expectation)
  end
end

class Contracts::Nothrows < Contracts::Base
  def on_exception(rv, method, receiver, *args, &blk)
    raise Contracts::Error, "Nothrow method `#{method_name}` raised exception: #{$!}", caller[5..-1]
  end
end

module Contracts::ClassMethods
  def Nothrow
    Contracts::Nothrows.new
  end
end
