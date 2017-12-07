# frozen_string_literal: true

require 'spec_helper'
require 'rspec_kickstarter/config'

module RSpecKickstarter
  ::RSpec.describe Config do
    describe '.instance' do
      it 'returns the singleton instance' do
        expect { described_class.instance }.not_to raise_error
      end
    end

    describe '.new' do
      it 'raises NoMethodError' do
        expect { described_class.new }.to raise_error(NoMethodError)
      end
    end
  end
end
