# -*- encoding: utf-8 -*-
# frozen_string_literal: true

require 'spec_helper'
require 'rspec_kickstarter/version'

RSpec.describe RSpecKickstarter do

  describe RSpecKickstarter::VERSION do
    it 'exists' do
      expect(RSpecKickstarter::VERSION).not_to be_nil
    end
  end

end
