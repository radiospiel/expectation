#--
# Author::    radiospiel  (mailto:eno@radiospiel.org)
# Copyright:: Copyright (c) 2011, 2012 radiospiel
# License::   Distributes under the terms of the Modified BSD License,
#             see LICENSE.BSD for details.
#++

# The Expectation::MultiMatcher class provides support for T1 | T2 matches.

class Expectation::MultiMatcher < Array
  def initialize(lhs, rhs)
    push lhs
    push rhs
  end

  def |(other)
    push other
  end
end

class Module
  def |(other)
    Expectation::MultiMatcher.new(self, other)
  end
end
