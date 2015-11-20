#--
# Author::    radiospiel  (mailto:eno@radiospiel.org)
# Copyright:: Copyright (c) 2011, 2012 radiospiel
# License::   Distributes under the terms of the Modified BSD License,
#             see LICENSE.BSD for details.
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

      # instance methods are UnboundMethod, class methods are Method.
      rv = @method.is_a?(Method) ? @method.call(*args, &blk)
                                 : @method.bind(receiver).call(*args, &blk)

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
    def singleton_method_added(name)
      if annotations = Contracts.consume_current_contracts
        method = singleton_method(name)
        annotated_method = Contracts::AnnotatedMethod.new(method, annotations)

        klass = self

        define_singleton_method name do |*args, &blk|
          annotated_method.invoke klass, *args, &blk
        end
      end

      super
    end

    def method_added(name)
      if annotations = Contracts.consume_current_contracts
        method = instance_method(name)
        annotated_method = Contracts::AnnotatedMethod.new(method, annotations)

        define_method name do |*args, &blk|
          annotated_method.invoke self, *args, &blk
        end
      end

      super
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
    # contains the method once the contract is initialized, which happens
    # in the Class#{singleton_,}method_added callback.
    attr :method, true

    #
    # Returns a description of the method; i.e. Class#name or Class.name
    def method_name
      if method.is_a?(Method)                               # A singleton method?
        # The method owner is the singleton class of the class. Sadly, the
        # the singleton class has no name; hence we try to construct the name
        # from its to_s description.
        klass_name = method.owner.to_s.gsub(/#<(.*?):(.*)>/, "\\2")
        "#{klass_name}.#{method.name}"
      else
        "#{method.owner}##{method.name}"
      end
    end

    private

    def error!(message)
      raise Contracts::Error, message, caller[6..-1]
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
    args.each_with_index do |value, idx|
      next unless expectation = expectations_ary[idx]
      Expectation::Matcher.match! value, expectation
    end
  rescue Expectation::Error
    error! "#{$!} in call to `#{method_name}`"
  end

  private

  def expectations_ary
    @expectations_ary ||= begin
      method.parameters.map do |flag, parameter_name|
        expectations[parameter_name]
      end
    end
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
    Expectation::Matcher.match! rv, expectation
  rescue Expectation::Error
    error! "#{$!} in return of `#{method_name}`"
  end
end

module Contracts::ClassMethods
  def Returns(expectation)
    Contracts::Returns.new(expectation)
  end
end

class Contracts::Nothrows < Contracts::Base
  def on_exception(rv, method, receiver, *args, &blk)
    error! "Nothrow method `#{method_name}` raised exception: #{$!}"
  end
end

module Contracts::ClassMethods
  def Nothrow
    Contracts::Nothrows.new
  end
end
