#--
# Author::    radiospiel  (mailto:eno@radiospiel.org)
# Copyright:: Copyright (c) 2011, 2012 radiospiel
# License::   Distributes under the terms of the Modified BSD License,
#             see LICENSE.BSD for details.
#++

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
