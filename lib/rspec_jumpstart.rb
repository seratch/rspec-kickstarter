# frozen_string_literal: true

require "rspec_jumpstart/generator"
require "rspec_jumpstart/config"
require "rspec_jumpstart/version"

#
# RSpecJumpstart Facade
#
module RSpecJumpstart
  class << self
    # Returns RSpecJumpstart's configuration object.
    # @api private
    def config
      @config ||= RSpecJumpstart::Config.instance
      yield @config if block_given?
      @config
    end
    alias configure config

    def version
      VERSION
    end
  end

  def self.write_spec(file_path, spec_dir = "./spec", force_write: false, dry_run: false)
    generator = RSpecJumpstart::Generator.new(spec_dir)
    generator.write_spec(file_path, force_write, dry_run)
  end
end
