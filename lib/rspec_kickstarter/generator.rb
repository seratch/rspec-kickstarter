# -*- encoding: utf-8 -*-

require 'erb'
require 'rdoc'
require 'rdoc/generator'
require 'rdoc/options'
require 'rdoc/parser/ruby'
require 'rdoc/stats'
require 'rspec_kickstarter'

class RSpecKickstarter::Generator

  attr_accessor :spec_dir, :delta_templtae, :full_template

  def initialize(spec_dir = './spec', delta_template = nil, full_template = nil)
    @spec_dir = spec_dir.gsub(/\/$/, '')
    @delta_template = delta_template
    @full_template = full_template
  end

  def write_spec(file_path, force_write = false, dry_run = false, rails_mode = false)

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
          methods_to_generate = lacking_methods

          if ! @delta_template.nil? 
            additional_spec = ERB.new(@delta_template, nil, '-', '_additional_spec_code').result(binding)
          elsif rails_mode && spec_path.match(/controllers/)
            additional_spec = ERB.new(RAILS_CONTROLLER_METHODS_PART_TEMPLATE, nil, '-', '_additional_spec_code').result(binding)
          elsif rails_mode && spec_path.match(/helpers/)
            additional_spec = ERB.new(RAILS_HELPER_METHODS_PART_TEMPLATE, nil, '-', '_additional_spec_code').result(binding)
          else
            additional_spec = ERB.new(BASIC_METHODS_PART_TEMPLATE, nil, '-', '_additional_spec_code').result(binding)
          end

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
        methods_to_generate = c.method_list.select { |m| m.visibility == :public }

        if ! @full_template.nil?
          code = ERB.new(@full_template, nil, '-', '_new_spec_code').result(binding)
        elsif rails_mode && self_path.match(/controllers/) 
          code = ERB.new(RAILS_CONTROLLER_NEW_SPEC_TEMPLATE, nil, '-', '_new_spec_code').result(binding)
        elsif rails_mode && self_path.match(/helpers/) 
          code = ERB.new(RAILS_HELPER_NEW_SPEC_TEMPLATE, nil, '-', '_new_spec_code').result(binding)
        else
          code = ERB.new(BASIC_NEW_SPEC_TEMPLATE, nil, '-', '_new_spec_code').result(binding)
        end

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
        "      #{instance_name(c)} = #{get_complete_class_name(c)}.new\n"
      else
        get_params_initialization_code(constructor) +
          "      #{instance_name(c)} = #{get_complete_class_name(c)}.new(#{to_param_names_array(constructor.params).join(', ')})\n"
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
    code.empty? ? "" : "#{code}\n"
  end

  #
  # e.g. BarBaz.do_something(a, b) { |c| }
  #
  def get_method_invocation_code(c, method)
    target = method.singleton ? get_complete_class_name(c) : instance_name(c)
    "#{target}.#{method.name}(#{to_param_names_array(method.params).join(', ')})#{get_block_code(method)}"
  end

  #
  # e.g. do_something(a, b) { |c| }
  #
  def get_rails_helper_method_invocation_code(method)
    "#{method.name}(#{to_param_names_array(method.params).join(', ')})#{get_block_code(method)}"
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

  def get_rails_http_method(method_name)
    http_method = RAILS_RESOURCE_METHOD_AND_HTTPMETHOD[method_name]
    http_method.nil? ? 'get' : http_method
  end

  BASIC_METHODS_PART_TEMPLATE = <<SPEC
<%- methods_to_generate.map { |method| %>
  # TODO auto-generated
  describe '<%= method.name %>' do
    it 'works' do
<%- unless get_instantiation_code(c, method).nil?      -%><%= get_instantiation_code(c, method) %><%- end -%>
<%- unless get_params_initialization_code(method).nil? -%><%= get_params_initialization_code(method) %><%- end -%>
      result = <%= get_method_invocation_code(c, method) %>
      expect(result).not_to be_nil
    end
  end
<% } %>
SPEC

  BASIC_NEW_SPEC_TEMPLATE = <<SPEC
# -*- encoding: utf-8 -*-

require 'spec_helper'
<% unless rails_mode then %>require '<%= self_path %>'
<% end -%>

describe <%= get_complete_class_name(c) %> do
<%= ERB.new(BASIC_METHODS_PART_TEMPLATE, nil, '-').result(binding) -%>
end
SPEC

  RAILS_RESOURCE_METHOD_AND_HTTPMETHOD = {
    'index'   => 'get',
    'new'     => 'get',
    'create'  => 'post', 
    'show'    => 'get',
    'edit'    => 'get',
    'update'  => 'put',
    'destroy' => 'delete' 
  }

  RAILS_CONTROLLER_METHODS_PART_TEMPLATE = <<SPEC
<%- methods_to_generate.map { |method| %>
  # TODO auto-generated
  describe '<%= method.name %>' do
    it 'returns OK' do
      <%= get_rails_http_method(method.name) %> :<%= method.name %>, {}, {}
      expect(response.status).to eq(200)
    end
  end
<% } %>
SPEC

  RAILS_CONTROLLER_NEW_SPEC_TEMPLATE = <<SPEC
# -*- encoding: utf-8 -*-

require 'spec_helper'

describe <%= get_complete_class_name(c) %> do
<%= ERB.new(RAILS_CONTROLLER_METHODS_PART_TEMPLATE, nil, '-').result(binding) -%>
end
SPEC

  RAILS_HELPER_METHODS_PART_TEMPLATE = <<SPEC
<%- methods_to_generate.map { |method| %>
  # TODO auto-generated
  describe '<%= method.name %>' do
    it 'works' do
      result = <%= get_rails_helper_method_invocation_code(method) %>
      expect(result).not_to be_nil
    end
  end
<% } %>
SPEC

  RAILS_HELPER_NEW_SPEC_TEMPLATE = <<SPEC
# -*- encoding: utf-8 -*-

require 'spec_helper'

describe <%= get_complete_class_name(c) %> do
<%= ERB.new(RAILS_HELPER_METHODS_PART_TEMPLATE, nil, '-').result(binding) -%>
end
SPEC

end

