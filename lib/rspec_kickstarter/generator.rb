# -*- encoding: utf-8 -*-

require 'rdoc'
require 'rdoc/parser/ruby'
require 'rdoc/options'
require 'rdoc/generator'
require 'rdoc/stats'
require 'rspec_kickstarter'

class RSpecKickstarter::Generator

  attr_accessor :spec_dir

  def initialize(spec_dir = './spec')
    @spec_dir = spec_dir.gsub(/\/$/, '')
  end

  def write_spec(file_path, force_write = false, dry_run = false)

    top_level = get_ruby_parser(file_path).scan
    c = extract_target_class_or_module(top_level)

    if c.nil?
      puts "#{file_path} skipped (Class/Module not found)."
    else

      spec_path = get_spec_path(file_path)

      if force_write && File.exist?(spec_path)
        # Append to the existing spec or skip

        existing_spec = File.read(spec_path)
        lacking_methods = c.method_list
          .select { |m| m.visibility == :public }
          .reject { |m| existing_spec.match(m.name) }

        if lacking_methods.empty? 
          puts "#{spec_path} skipped."
        else
          additional_spec = <<SPEC
#{lacking_methods.map { |method|
  <<EACH_SPEC
  # TODO auto-generated
  describe '#{method.name}' do
    it 'works' do#{get_instantiation_code(c, method)}#{get_params_initialization_code(method)}
      result = #{get_method_invocation_code(c, method)}
      expect(result).not_to be_nil
    end
  end
EACH_SPEC
}.join("\n")}
SPEC
          last_end_not_found = true
          code = existing_spec.split("\n").reverse.reject { |line| 
            if last_end_not_found 
              last_end_not_found = line.gsub(/#.+$/, '').strip != "end"
              true
            else
              false
            end
          }.reverse.join("\n") + "\n" + additional_spec + "\nend\n"
          if dry_run
            puts "----- #{spec_path} -----"
            puts code
          else
            File.open(spec_path, 'w') { |f| f.write(code) }
          end
          puts "#{spec_path} modified."
        end

      else
        # Create a new spec 

        self_path = to_string_value_to_require(file_path)
        code = <<SPEC
# -*- encoding: utf-8 -*-
require 'spec_helper'
require '#{self_path}'

describe #{get_complete_class_name(c)} do

#{c.method_list
  .select { |m| m.visibility == :public }
  .map { |method| 
  <<EACH_SPEC
  # TODO auto-generated
  describe '#{method.name}' do
    it 'works' do#{get_instantiation_code(c, method)}#{get_params_initialization_code(method)}
      result = #{get_method_invocation_code(c, method)}
      expect(result).not_to be_nil
    end
  end
EACH_SPEC
}.join("\n")}
end
SPEC
        if dry_run
          puts "----- #{spec_path} -----"
          puts code
        else
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

  #
  # Creates new RDoc::Parser::Ruby instance.
  #
  def get_ruby_parser(file_path)
    top_level = RDoc::TopLevel.new(file_path)
    if RUBY_VERSION.to_f < 2.0
      # reset is removed since 2.0
      RDoc::TopLevel.reset()
    end

    # RDoc::Stats initialization
    if RUBY_VERSION.to_f >= 2.0
      # Ruby 2.0 requires RDoc::Store internally.
      store = RDoc::Store.new
      top_level.store = store
      stats = RDoc::Stats.new(store, 1)
    else
      stats = RDoc::Stats.new(1)
    end

    RDoc::Parser::Ruby.new(
      top_level,
      file_path,
      File.read(file_path),
      RDoc::Options.new,
      stats
    )
  end

  #
  # Extracts RDoc::NormalClass/RDoc::NormalModule from RDoc::TopLevel.
  #
  def extract_target_class_or_module(top_level)
    c = top_level.classes.first
    if c.nil?
      m = top_level.modules.first
      if m.nil?
        top_level.is_a?(RDoc::NormalModule) ? top_level : nil
      else
        extract_target_class_or_module(m)
      end
    else
      c
    end
  end

  #
  # Gets the complete class name from RDoc::NormalClass/RDoc::NormalModule instance.
  #
  def get_complete_class_name(c, name = c.name)
    if !c.parent.name.nil? && c.parent.is_a?(RDoc::NormalModule)
      get_complete_class_name(c.parent, "#{c.parent.name}::#{name}")
    else
      name
    end
  end

  #
  # Returns spec file path.
  # e.g. "lib/foo/bar_baz.rb" -> "spec/foo/bar_baz_spec.rb"
  #
  def get_spec_path(file_path)
    spec_dir + '/' + file_path.gsub(/^\.\//, '').gsub(/^(lib\/)|(app\/)/, '').gsub(/\.rb$/, '_spec.rb')
  end

  #
  # Returns string value to require.
  # e.g. "lib/foo/bar_baz.rb" -> "foo/bar_baz"
  #
  def to_string_value_to_require(file_path)
    file_path.gsub(/^(lib\/)|(app\/)/, '').gsub(/\.rb$/, '')
  end

  # 
  # Returns snake_case name.
  # e.g. FooBar -> "foo_bar"
  #
  def instance_name(c)
    c.name
      .gsub(/::/, '/')
      .gsub(/([A-Z]+)([A-Z][a-z])/,'\1_\2')
      .gsub(/([a-z\d])([A-Z])/,'\1_\2')
      .tr("-", "_")
      .downcase
  end

  #
  # Extracts parameter names as an *Array*.
  # e.g. "()" -> []
  # e.g. "(a, b = 'foo')" -> ["a", "b"]
  #
  def to_param_names_array(params)
    params.split(',').map { |p| p.gsub(/[\(\)\s]/, '').gsub(/=.+$/, '') }.reject { |p| p.nil? || p.empty? }
  end

  # 
  # Code generation
  #

  #
  # e.g.
  #     a = stub('a')
  #     b = stub('b')
  #     bar_baz = BarBaz.new(a, b)
  #
  def get_instantiation_code(c, method)
    if method.singleton
      ""
    else
      constructor = c.method_list.find { |m| m.name == 'new' }
      if constructor.nil?
        "\n      #{instance_name(c)} = #{get_complete_class_name(c)}.new"
      else
        get_params_initialization_code(constructor) +
          "\n      #{instance_name(c)} = #{get_complete_class_name(c)}.new(#{to_param_names_array(constructor.params).join(', ')})"
      end
    end
  end

  #
  # e.g.
  #     a = stub('a')
  #     b = stub('b')
  #
  def get_params_initialization_code(method)
    code = to_param_names_array(method.params).map { |p| "      #{p} = stub('#{p}')" }.join("\n")
    code.empty? ? "" : "\n#{code}"
  end

  #
  # e.g. BarBaz.do_something(a, b) { |c| }
  #
  def get_method_invocation_code(c, method)
    if method.singleton
      "#{get_complete_class_name(c)}.#{method.name}(#{to_param_names_array(method.params).join(', ')})#{get_block_code(method)}"
    else
      "#{instance_name(c)}.#{method.name}(#{to_param_names_array(method.params).join(', ')})#{get_block_code(method)}"
    end
  end

  #
  # e.g. { |a, b| }
  #
  def get_block_code(method)
    if method.block_params.nil? || method.block_params.empty?
      ""
    else
      " { |#{method.block_params}| }"
    end
  end

end

