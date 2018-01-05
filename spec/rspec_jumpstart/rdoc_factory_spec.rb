# frozen_string_literal: true

require 'spec_helper'
require 'rspec_jumpstart/rdoc_factory'

RSpec.describe RSpecJumpstart::RDocFactory do

  describe '#get_rdoc_class_or_module' do
    it 'works' do
      file_path = 'lib/rspec_jumpstart.rb'
      result = described_class.get_rdoc_class_or_module(file_path)
      expect(result).not_to be_nil
    end

    it 'works with Ruby 2.0' do
      unless defined?(RDoc::Store)
        module RDoc
          class Store
          end

          class TopLevel
            def store=(*); end
          end
        end

        begin
          file_path = 'lib/rspec_jumpstart.rb'
          result = described_class.get_rdoc_class_or_module(file_path)
          expect(result).not_to be_nil
        ensure
          RDoc.class_eval do
            remove_const :Store
          end
        end
      end
    end
  end

end
