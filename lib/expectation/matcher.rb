#--
# Author::    radiospiel  (mailto:eno@radiospiel.org)
# Copyright:: Copyright (c) 2011, 2012 radiospiel
# License::   Distributes under the terms of the Modified BSD License,
#             see LICENSE.BSD for details.
#++

# The Expectation::Matcher module implements the logic to match a value
# against a pattern.

require "uri"

module Expectation::Matcher
  class Mismatch < ArgumentError
    attr_reader :value, :expectation, :info

    def initialize(value, expectation, info = nil)
      @value = value
      @expectation = expectation
      @info = info
    end

    def to_s
      message = "#{value.inspect} does not match #{expectation.inspect}"
      case info
      when nil     then message
      when Integer then "#{message}, at index #{info}"
      else              "#{message}, at key #{info.inspect}"
      end
    end
  end

  extend self

  #
  # Does a value match an expectation?
  def match?(value, expectation)
    match! value, expectation
    true
  rescue Mismatch
    false
  end

  #
  # Matches a value against an expectation. Raises an Expectation::Mismatch
  # if the expectation could not be matched.
  #
  # The info parameter is used to add some position information to
  # any Mismatch raised.
  def match!(value, expectation, info = nil)
    match = case expectation
            when :truish  then !!value
            when :fail    then false
            when Array    then
              if expectation.length == 1
                # Array as "array of elements matching an expectation"; for example
                # [1,2,3] => [Integer]
                e = expectation.first
                value.each_with_index { |v, idx| match!(v, e, idx) }
              else
                # Array as "object matching one of given expectations
                expectation.any? { |e| _match?(value, e) }
              end
            when Proc     then expectation.arity == 0 ? expectation.call : expectation.call(value)
            when Regexp   then value.is_a?(String) && expectation =~ value
            when :__block then value.call
            when Hash     then Hash === value &&
                               expectation.each { |key, exp| match! value[key], exp, key }
            when Module
              if expectation == URI
                _match_uri?(value)
              else
                expectation === value
              end
            else expectation === value
    end

    return if match
    fail Mismatch.new(value, expectation, info)
  end

  private

  def _match_uri?(value)
    URI.parse(value)
    true
  rescue URI::InvalidURIError
    false
  end

  def _match?(value, expectation)
    match! value, expectation
    true
  rescue Mismatch
    false
  end
end
