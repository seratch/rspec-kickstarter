# frozen_string_literal: true

require 'spec_helper'
require 'rspec_jumpstart/version'

RSpec.describe RSpecJumpstart do

  describe RSpecJumpstart::VERSION do
    it 'exists' do
      expect(RSpecJumpstart::VERSION).not_to be_nil
    end
  end

end
