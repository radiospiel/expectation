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
require "logger"

module Contracts
  class Error < ArgumentError; end

  (class << self; self; end).class_eval do
    attr :logger, true
  end
  self.logger = Logger.new(STDOUT)

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
      #
      # Some contracts might need a per-invocation scope. If that is the take
      # their before_call method will return their specific scope, and we'll
      # carry that over to the after_call and on_exception calls.
      #
      # Since this is potentially costly we do rather not create a combined
      # scope object unless we really need it; also there is an optimized
      # code path for after_call's in effect. (Not for on_exception though;
      # since they should only occur in exceptional situations they can carry
      # a bit of performance penalty just fine.)
      #
      # TODO: This could be improved by having a each annotation take care of
      # each individual call; a first experiment to do that, however, failed.
      annotation_scopes = nil

      @before_annotations.each do |annotation|
        next unless annotation_scope = annotation.before_call(receiver, *args, &blk)
        annotation_scopes ||= {}
        annotation_scopes[annotation.object_id] = annotation_scope
      end

      # instance methods are UnboundMethod, class methods are Method.
      rv = @method.is_a?(Method) ? @method.call(*args, &blk)
                                 : @method.bind(receiver).call(*args, &blk)

      if annotation_scopes
        @after_annotations.each do |annotation|
          annotation.after_call(annotation_scopes[annotation.object_id], rv, receiver, *args, &blk)
        end
      else
        @after_annotations.each do |annotation|
          annotation.after_call(nil, rv, receiver, *args, &blk)
        end
      end

      return rv
    rescue StandardError => exc
      @exception_annotations.each do |annotation|
        annotation.on_exception(annotation_scopes && annotation_scopes[annotation.object_id], exc, receiver, *args, &blk)
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

    nil
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

  def after_call(_, rv, receiver, *args, &blk)
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
  def on_exception(_, rv, method, receiver, *args, &blk)
    error! "Nothrow method `#{method_name}` raised exception: #{$!}"
  end
end

module Contracts::ClassMethods
  def Nothrow
    Contracts::Nothrows.new
  end
end

class Contracts::Runtime < Contracts::Base
  attr :expected_runtime, :max

  def initialize(expected_runtime, options)
    @expected_runtime = expected_runtime
    @max = options[:max]

    expect! max.nil? || expected_runtime <= max
  end

  def before_call(receiver, *args, &blk)
    return Time.now
  end

  def after_call(starts_at, rv, receiver, *args, &blk)
    runtime = Time.now - starts_at

    if max && runtime >= max
      error! "#{method_name} took longer than allowed: %.02f secs > %.02f secs." % [ runtime, expected_runtime ]
    end

    if runtime >= expected_runtime
      Contracts.logger.warn "#{method_name} took longer than expected: %.02f secs > %.02f secs." % [ runtime, expected_runtime ]
    end
  end

  def logger
    self.class.logger
  end
end

module Contracts::ClassMethods
  include Contracts

  +Expects(expected_runtime: Numeric)
  +Expects(options: { max: [ Numeric, nil ] })
  def Runtime(expected_runtime, options = {})
    Contracts::Runtime.new expected_runtime, options
  end
end
