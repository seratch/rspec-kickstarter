# -*- encoding: utf-8 -*-

require 'rdoc'
require 'rdoc/parser/ruby'
require 'rdoc/options'
require 'rdoc/stats'

module RSpecKickstarter
  class Generator

    attr_accessor :spec_dir

    def initialize(spec_dir = './spec')
      @spec_dir = spec_dir.gsub(/\/$/, '')
    end

    def get_target(top_level)
      c = top_level.classes.first
      if c.nil?
        m = top_level.modules.first
        if m.nil?
          top_level.is_a?(RDoc::NormalModule) ? top_level : nil
        else
          get_target(m)
        end
      else
        c
      end
    end

    def get_complete_class_name(c, name = c.name)
      if !c.parent.name.nil? && c.parent.is_a?(RDoc::NormalModule)
        get_complete_class_name(c.parent, "#{c.parent.name}::#{name}")
      else
        name
      end
    end

    def instance_name(c)
      # TODO prefer snake_case
      c.name.downcase
    end

    def to_param_names_array(params)
      params.split(',').map { |p| p.gsub(/[\(\)\s]/, '').gsub(/=.+$/, '') }.reject { |p| p.nil? || p.empty? }
    end

    def get_params_initialization_code(method)
      code = to_param_names_array(method.params).map { |p| "      #{p} = stub('#{p}')" }.join("\n")
      code.empty? ? "" : "\n#{code}"
    end

    def get_instantiation_code(c, method)
      if method.singleton
        ""
      else
        constructor = c.method_list.find { |m| m.name == :new }
        if constructor.nil?
          "\n      #{instance_name(c)} = stub('#{instance_name(c)}')"
        else
          get_params_initialization_code(constructor) +
              "\n      #{instance_name(c)} = #{get_complete_class_name(c)}.new#{constructor.params}"
        end
      end
    end

    def get_method_invocation_code(c, method)
      if method.singleton
        "#{get_complete_class_name(c)}.#{method.name}(#{to_param_names_array(method.params).join(', ')})#{get_block_code(method)}"
      else
        "#{instance_name(c)}.#{method.name}(#{to_param_names_array(method.params).join(', ')})#{get_block_code(method)}"
      end
    end

    def get_block_code(method)
      if method.block_params.nil? || method.block_params.empty?
        ""
      else
        " { |#{method.block_params}| }"
      end
    end

    def wite_spec_if_absent(file_path)

      body = File.read(file_path)
      RDoc::TopLevel.reset()
      top_level = RDoc::TopLevel.new(file_path)
      parser = RDoc::Parser::Ruby.new(
          top_level,
          file_path,
          body,
          RDoc::Options.new,
          RDoc::Stats.new(1)
      )
      top_level = parser.scan
      c = get_target(top_level)

      if c.nil?
        puts "#{file_path} skipped (Class/Module not found)."
      else

        self_path = file_path.gsub(/^(lib\/)|(app\/)/, '').gsub(/\.rb$/, '')
        code = <<SPEC
# -*- encoding: utf-8 -*-
require 'spec_helper'
require '#{self_path}'

describe #{get_complete_class_name(c)} do

#{c.method_list.select { |m| m.visibility == :public }.map { |method|
          <<EACH_SPEC
                    describe '#{method.name}' do
    it 'should work' do#{get_instantiation_code(c, method)}#{get_params_initialization_code(method)}
      result = #{get_method_invocation_code(c, method)}
      # result.should_not be_nil
    end
  end
EACH_SPEC
}.join("\n")}
end
SPEC

        # TODO improve the logic
        spec_path = spec_dir + '/' + file_path.gsub(/^(lib\/)|(app\/)/, '').gsub(/\.rb$/, '_spec.rb')
        if File.exist?(spec_path)
          puts "#{spec_path} already exists."
        else
          FileUtils.mkdir_p(File.dirname(spec_path))
          File.open(spec_path, 'w') { |f| f.write(code) }
          puts "#{spec_path} created."
        end
      end
    end
  end
end

