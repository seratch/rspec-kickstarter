# -*- encoding: utf-8 -*-
require 'spec_helper'
require 'rspec_kickstarter/version'

describe RSpecKickstarter do

  describe RSpecKickstarter::VERSION do
    it 'exists' do
      RSpecKickstarter::VERSION.should_not be_nil
    end
  end

end
