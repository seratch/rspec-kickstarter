# -*- encoding: utf-8 -*-

require 'rdoc'
require 'rdoc/generator'
require 'rdoc/options'
require 'rdoc/parser/ruby'
require 'rdoc/stats'
require 'rspec_kickstarter'

#
# RDoc instance factory
#
module RSpecKickstarter
  class RDocFactory

    #
    # Returns RDoc::NormalClass/RDoc::NormalModule instance.
    #
    def self.get_rdoc_class_or_module(file_path)
      top_level = get_ruby_parser(file_path).scan
      extract_target_class_or_module(top_level)
    end

    #
    # Creates new RDoc::Parser::Ruby instance.
    #
    def self.get_ruby_parser(file_path)
      top_level = RDoc::TopLevel.new(file_path)
      if RUBY_VERSION.to_f < 2.0
        # reset is removed since 2.0
        RDoc::TopLevel.reset
      end

      # RDoc::Stats initialization
      if defined?(RDoc::Store)
        # RDoc 4.0.0 requires RDoc::Store internally.
        store = RDoc::Store.new
        top_level.store = store
        stats = RDoc::Stats.new(store, 1)
      else
        stats = RDoc::Stats.new(1)
      end

      RDoc::Parser::Ruby.new(
          top_level,
          file_path,
          File.read(file_path),
          RDoc::Options.new,
          stats
      )
    end

    #
    # Extracts RDoc::NormalClass/RDoc::NormalModule from RDoc::TopLevel.
    #
    def self.extract_target_class_or_module(top_level)
      c = top_level.classes.first
      if c.nil?
        m = top_level.modules.first
        if m.nil?
          top_level.is_a?(RDoc::NormalModule) ? top_level : nil
        else
          extract_target_class_or_module(m)
        end
      else
        c
      end
    end

  end
end
