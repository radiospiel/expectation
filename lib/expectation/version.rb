#--
# Author::    radiospiel  (mailto:eno@radiospiel.org)
# Copyright:: Copyright (c) 2011, 2012 radiospiel
# License::   Distributes under the terms of the Modified BSD License,
#             see LICENSE.BSD for details.
module Expectation
  module GemHelper
    extend self

    def version(name)
      spec = Gem.loaded_specs[name]
      version = spec.version.to_s
      version += "+unreleased" if unreleased?(spec)
      version
    end

    private

    def unreleased?(spec)
      return false unless defined?(Bundler::Source::Gemspec)
      return true if spec.source.is_a?(::Bundler::Source::Gemspec)
      return true if spec.source.is_a?(::Bundler::Source::Path)
      false
    end
  end

  VERSION = GemHelper.version "expectation"
end
