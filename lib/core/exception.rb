#--
# Author::    radiospiel  (mailto:eno@radiospiel.org)
# Copyright:: Copyright (c) 2011, 2012 radiospiel
# License::   Distributes under the terms of the Modified BSD License, see LICENSE.BSD for details.
#++

class Exception
  def self.raise!(*args)
    raise_with_skipped_entries! 1, *args
  end

  # Create an ArgumentError with an adjusted backtrace. We don't want to 
  # see the user all the annotation internals.
  def self.raise_with_skipped_entries!(skip_entries, *args)
    adjusted_backtrace = caller[(1+skip_entries) .. -1]
    
    exception = new(*args)
    exception.singleton_class.send(:define_method, :backtrace) do
      adjusted_backtrace
    end
    raise exception
  end
end

