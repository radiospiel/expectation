#--
# Author::    radiospiel  (mailto:eno@radiospiel.org)
# Copyright:: Copyright (c) 2011, 2012 radiospiel
# License::   Distributes under the terms of the Modified BSD License, see LICENSE.BSD for details.
#++

class Exception
  # Create an ArgumentError with an adjusted backtrace. We don't want to 
  # see the user all the annotation internals.
  def self.raise_with_backtrace!(backtrace, *args)
    exception = new(*args)
    exception.singleton_class.send(:define_method, :backtrace) do
      backtrace
    end
    raise exception
  end
end

