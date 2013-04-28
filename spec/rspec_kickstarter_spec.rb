# -*- encoding: utf-8 -*-
require 'spec_helper'

describe RSpecKickstarter do

  describe 'write_spec' do
    it 'should work' do
      file_path = 'lib/rspec_kickstarter.rb'
      spec_dir = './spec'
      force_write = false
      dry_run = false
      RSpecKickstarter.write_spec(file_path, spec_dir, force_write, dry_run)
    end
  end

end
