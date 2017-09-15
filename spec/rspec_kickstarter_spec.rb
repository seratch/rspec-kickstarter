# frozen_string_literal: true

require 'spec_helper'

RSpec.describe RSpecKickstarter do

  describe '#write_spec' do
    it 'works' do
      file_path = 'lib/rspec_kickstarter.rb'
      spec_dir = './spec'
      force_write = false
      dry_run = false
      described_class.write_spec(file_path, spec_dir, force_write, dry_run)
    end
  end

end
