# frozen_string_literal: true

require 'rspec_kickstarter/generator'
require 'rspec_kickstarter/config'
require 'rspec_kickstarter/version'

#
# RSpecKickstarter Facade
#
module RSpecKickstarter
  class << self
    # Returns RSpecKickstarter's configuration object.
    # @api private
    def config
      @config ||= RSpecKickstarter::Config.instance
      yield @config if block_given?
      @config
    end
    alias configure config

    def version
      VERSION::STRING
    end
  end

  def self.write_spec(file_path, spec_dir = './spec', force_write = false, dry_run = false)
    generator = RSpecKickstarter::Generator.new(spec_dir)
    generator.write_spec(file_path, force_write, dry_run)
  end
end
