#--
# Author::    radiospiel  (mailto:eno@radiospiel.org)
# Copyright:: Copyright (c) 2011, 2012 radiospiel
# License::   Distributes under the terms of the Modified BSD License, see LICENSE.BSD for details.
#++

# The Expectation::Annotations module provides annotation support. That basically
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
module ::Expectation::Annotations
end

class Class
  module Annotations
    def self.current_annotations
      Thread.current[:current_annotations] ||= []
    end

    def self.consume_current_annotations
      r, Thread.current[:current_annotations] = Thread.current[:current_annotations], nil
      r
    end

    class Base
      def +@
        Class::Annotations.current_annotations << self
      end

      # contains the unbound method once the Base object is initialized
      attr :method, true

      def to_s
        "#{method.owner}##{method.name}"
      end
    end

    class AnnotatedMethod
      def initialize(method, annotations)
        @method = method

        @before_annotations = annotations.select { |annotation| annotation.respond_to?(:before_call) }
        @after_annotations  = annotations.select { |annotation| annotation.respond_to?(:after_call) }

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

        rv
      end
    end

    private

    def method_added(name)
      return unless annotations = Class::Annotations.consume_current_annotations

      method = instance_method(name)
      annotated_method = AnnotatedMethod.new(method, annotations)

      define_method name do |*args, &blk|
        annotated_method.invoke self, *args, &blk
      end
    end
  end

  def enable_annotations!
    extend Annotations
  end
end

class ::Expectation::Annotations::ExpectationAnnotation < ::Class::Annotations::Base
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
    raise ArgumentError, "#{$!} in call to `#{self}`", caller[5..-1]
  end
end

class ::Expectation::Annotations::ReturnsAnnotation < ::Class::Annotations::Base
  attr :expectation

  def initialize(expectation)
    @expectation = expectation
  end

  def after_call(rv, method, receiver, *args, &blk)
    Expectation.match! rv, expectation
  rescue Expectation::Error
    raise ArgumentError, "#{$!} in return of `#{self}`", caller[5..-1]
  end
end

def Expects(expectation)
  expect! expectation => Hash
  ::Expectation::Annotations::ExpectationAnnotation.new(expectation)
end

def Returns(expectation)
  ::Expectation::Annotations::ReturnsAnnotation.new(expectation)
end
