#--
# Author::    radiospiel  (mailto:eno@radiospiel.org)
# Copyright:: Copyright (c) 2011, 2012 radiospiel
# License::   Distributes under the terms of the Modified BSD License,
#             see LICENSE.BSD for details.
#++

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
