# frozen_string_literal: true

require "rdoc"
require "rdoc/generator"
require "rdoc/options"
require "rdoc/parser/ruby"
require "rdoc/stats"
require "rspec_jumpstart"

#
# RDoc instance factory
#
module RSpecJumpstart
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

      # RDoc 4.0.0 requires RDoc::Store internally.
      store           = RDoc::Store.new
      top_level.store = store
      stats           = RDoc::Stats.new(store, 1)

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
      return c if c

      m = top_level.modules.first
      if m.nil?
        top_level.is_a?(RDoc::NormalModule) ? top_level : nil
      else
        extract_target_class_or_module(m)
      end
    end

  end
end
