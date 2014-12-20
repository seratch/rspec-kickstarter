# -*- encoding: utf-8 -*-

require 'erb'
require 'rspec_kickstarter'
require 'rspec_kickstarter/erb_templates'

#
# ERB instance provider
#
module RSpecKickstarter
  class ERBFactory

    def initialize(custom_template)
      @custom_template = custom_template
    end

    #
    # Returns ERB instance for creating new spec
    #
    def get_instance_for_new_spec(rails_mode, target_path)
      template = get_erb_template(@custom_template, true, rails_mode, target_path)
      ERB.new(template, nil, '-', '_new_spec_code')
    end

    #
    # Returns ERB instance for appeding lacking tests
    #
    def get_instance_for_appending(rails_mode, target_path)
      template = get_erb_template(@custom_template, false, rails_mode, target_path)
      ERB.new(template, nil, '-', '_additional_spec_code')
    end

    private

    #
    # Returns ERB template
    #
    def get_erb_template(custom_template, is_full, rails_mode, target_path)
      if custom_template
        custom_template
      elsif rails_mode && target_path.match(/controllers/)
        get_rails_controller_template(is_full)
      elsif rails_mode && target_path.match(/helpers/)
        get_rails_helper_template(is_full)
      else
        get_basic_template(is_full)
      end
    end

    def get_rails_controller_template(is_full)
      if is_full
        RSpecKickstarter::ERBTemplates::RAILS_CONTROLLER_NEW_SPEC_TEMPLATE
      else
        RSpecKickstarter::ERBTemplates::RAILS_CONTROLLER_METHODS_PART_TEMPLATE
      end
    end

    def get_rails_helper_template(is_full)
      if is_full
        RSpecKickstarter::ERBTemplates::RAILS_HELPER_NEW_SPEC_TEMPLATE
      else
        RSpecKickstarter::ERBTemplates::RAILS_HELPER_METHODS_PART_TEMPLATE
      end
    end

    def get_basic_template(is_full)
      if is_full
        RSpecKickstarter::ERBTemplates::BASIC_NEW_SPEC_TEMPLATE
      else
        RSpecKickstarter::ERBTemplates::BASIC_METHODS_PART_TEMPLATE
      end
    end

  end
end
