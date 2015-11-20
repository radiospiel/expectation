#--
# Author::    radiospiel  (mailto:eno@radiospiel.org)
# Copyright:: Copyright (c) 2011, 2012 radiospiel
# License::   Distributes under the terms of the Modified BSD License,
#             see LICENSE.BSD for details.
#++

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
