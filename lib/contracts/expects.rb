#--
# Author::    radiospiel  (mailto:eno@radiospiel.org)
# Copyright:: Copyright (c) 2011, 2012 radiospiel
# License::   Distributes under the terms of the Modified BSD License,
#             see LICENSE.BSD for details.
#++

# The Contract module provides support for Expects annotations.

require "expectation"

class Contracts::Expects < Contracts::Base
  attr_reader :expectations

  def initialize(expectations)
    @expectations = expectations
  end

  def before_call(_receiver, *args, &_blk)
    args.each_with_index do |value, idx|
      next unless expectation = expectations_ary[idx]
      Expectation::Matcher.match! value, expectation
    end

    nil
  rescue Expectation::Error
    error! "#{$ERROR_INFO} in call to `#{method_name}`"
  end

  private

  def expectations_ary
    @expectations_ary ||= begin
      method.parameters.map do |_flag, parameter_name|
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
