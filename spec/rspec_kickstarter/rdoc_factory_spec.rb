# -*- encoding: utf-8 -*-

require 'spec_helper'
require 'rspec_kickstarter/rdoc_factory'

describe RSpecKickstarter::RDocFactory do

  describe '#get_rdoc_class_or_module' do
    it 'works' do
      file_path = 'lib/rspec_kickstarter.rb'
      result = RSpecKickstarter::RDocFactory.get_rdoc_class_or_module(file_path)
      expect(result).not_to be_nil
    end

    it 'works with Ruby 2.0' do
      unless defined?(RDoc::Store)
        class RDoc::Store; end
        class RDoc::TopLevel
          def store=(store); end
        end
        begin
          file_path = 'lib/rspec_kickstarter.rb'
          result = RSpecKickstarter::RDocFactory.get_rdoc_class_or_module(file_path)
          expect(result).not_to be_nil
        ensure
          RDoc.class_eval do remove_const :Store end
        end
      end
    end
  end

end
