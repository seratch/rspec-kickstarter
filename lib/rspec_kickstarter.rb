# -*- encoding: utf-8 -*-

require "rspec_kickstarter/generator"
require "rspec_kickstarter/version"

module RSpecKickstarter

  def self.write_spec(file_path, spec_dir, force_write = false, dry_run = false)
    generator = RSpecKickstarter::Generator.new(spec_dir)
    generator.write_spec(file_path, force_write, dry_run)
  end

end

