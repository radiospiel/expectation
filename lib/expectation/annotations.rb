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
#     expects! value1: Fixnum, value2: /.@./
#     returns! Fixnum
#
#     def bar(value1, value2)
#     end
#   end
#
module ::Expectation::Annotations
end

class Class
  module Annotations
    class AnnotatedMethod
      attr :method

      def initialize
        @before_annotations = []
        @after_annotations = []
      end
    
      def method=(method)
        @method          = method
        @parameter_names = method.parameters.map(&:last)
        @arity           = method.arity
      end

      def <<(annotation)
        @before_annotations << annotation if annotation.methods.include?(:before_call)
        @after_annotations << annotation if annotation.methods.include?(:after_call)
      end
      
      def to_s
        "#{method.owner}##{method.name}"
      end

      attr :before_annotations
      attr :after_annotations
      attr :parameter_names
      attr :arity
      
      def invoke(receiver, *args, &block)
        verify_number_of_arguments! args.count
        
        before_annotations.each do |annotation|
          annotation.before_call(self, receiver, *args, &block)
        end

        rv = method.bind(receiver).call(*args, &block)

        after_annotations.each do |annotation|
          annotation.after_call(rv, self, receiver, *args, &block)
        end

        rv
      end
      
      private
      
      def verify_number_of_arguments!(count)
        return if arity >= 0 && count == arity
        return if arity < 0 && count >= -arity

        ArgumentError.raise_with_skipped_entries! 2, "in `#{self}': wrong number of arguments (#{count} for #{-arity})"
      end
    end
    
    private

    def __consume__annotated_method
      r, @__annotated_method = @__annotated_method, nil
      r
    end
    
    def __annotated_method
      @__annotated_method ||= AnnotatedMethod.new
    end

    def method_added(name)
      return unless __annotated_method = __consume__annotated_method

      __annotated_method.method = instance_method(name)
      define_method name do |*args, &block|
        __annotated_method.invoke self, *args, &block
      end
    end
  end

  def enable_annotations!
    extend Annotations
  end
end

class ::Expectation::Annotations::ExpectationAnnotation
  attr :expectations

  def before_call(method, receiver, *args, &block)
    method.parameter_names.each_with_index do |parameter_name, idx|
      next unless idx <= args.length
      next unless expectation = expectations[parameter_name]
      next if Expectation.verify! args[idx], expectation
      
      Expectation::Error.raise_with_skipped_entries! 7, "#{Expectation.last_error}, in call to #{method}"
    end
  end
  
  def initialize(expectations)
    @expectations = expectations
  end
end

module Class::Annotations
  def expects!(expectation)
    expect! expectation => Hash
    __annotated_method << ::Expectation::Annotations::ExpectationAnnotation.new(expectation)
  end
end

class ::Expectation::Annotations::ReturnsAnnotation
  attr :expectation

  def after_call(rv, method, receiver, *args, &block)
    return if Expectation.verify! rv, expectation
    Expectation::Error.raise_with_skipped_entries! 2, "Invalid return value from #{method}: #{Expectation.last_error}"
  end
  
  def initialize(expectation)
    @expectation = expectation
  end
end

module Class::Annotations
  def returns!(expectation)
    __annotated_method << ::Expectation::Annotations::ReturnsAnnotation.new(expectation)
  end
end
