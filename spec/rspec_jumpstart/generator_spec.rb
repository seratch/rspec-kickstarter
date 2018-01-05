# frozen_string_literal: true

require 'spec_helper'
require 'rspec_jumpstart/generator'

RSpec.describe RSpecJumpstart::Generator do

  let(:generator) { described_class.new('tmp/spec') }

  describe '#initialize' do
    it 'works without params' do
      result = described_class.new

      expect(result).not_to be_nil
    end
    it 'works' do
      spec_dir = './spec'

      result = described_class.new(spec_dir)

      expect(result).not_to be_nil
    end
  end

  describe '#get_complete_class_name' do
    it 'works' do
      parent = double(:parent, name: nil)
      c      = double(:c, parent: parent)
      name   = 'ClassName'

      result = generator.get_complete_class_name(c, name)

      expect(result).to eql('ClassName')
    end

    it 'works' do
      parent = double(:parent, name: 'A')
      c      = double(:c, parent: parent)
      name   = 'A::ClassName'

      result = generator.get_complete_class_name(c, name)

      expect(result).to eql('A::ClassName')
    end
  end

  describe '#instance_name' do
    it 'works' do
      c = double(:c, name: 'generator')

      result = generator.instance_name(c)

      expect(result).to eql('generator')
    end
  end

  describe '#to_param_names_array' do
    it 'works' do
      params = "(a, b = 'foo', c = 123)"

      result = generator.to_param_names_array(params)

      expect(result).to eql(%w[a b c])
    end
  end

  describe '#get_params_initialization_code' do
    it 'works' do
      method = double(:method, params: "(a = 1,b = 'aaaa')")

      result = generator.get_params_initialization_code(method)
      expect(result).to eql("      a = double('a')\n      b = double('b')\n")
    end
  end

  describe '#get_instantiation_code' do
    it 'works with modules' do
      method = double(:method, singleton: true, name: 'do_something')
      c      = double(:c, name: 'Foo', method_list: [method])

      result = generator.get_instantiation_code(c, method)

      expect(result).to eql('')
    end

    it 'works with classes' do
      parent = double(:parent, name: nil)
      method = double(:method, singleton: false, name: 'do_something')
      c      = double(:c, name: 'Foo', parent: parent, method_list: [method])

      result = generator.get_instantiation_code(c, method)

      expect(result).to eql("      foo = described_class.new\n")
    end

    it 'works with classes' do
      parent = double(:parent, name: 'Parent')
      method = double(:method, singleton: false, name: 'do_something')
      c      = double(:c, name: 'Foo', parent: parent, method_list: [method])

      result = generator.get_instantiation_code(c, method)

      expect(result).to eql("      foo = described_class.new\n")
    end
  end

  describe '#get_method_invocation_code' do
    it 'works with modules' do
      parent = double(:parent, name: nil)
      method = double(:method,
                      singleton:    true,
                      name:         'do_something',
                      params:       '(a, b)',
                      block_params: '')
      c      = double(:c, name: 'Module', parent: parent, method_list: [method])

      result = generator.get_method_invocation_code(c, method)
      expect(result).to eql('described_class.do_something(a, b)')
    end
    it 'works with classes' do
      parent = double(:parent, name: 'Module')
      method = double(:method,
                      singleton:    false,
                      name:         'do_something',
                      params:       '(a, b)',
                      block_params: '')
      c      = double(:c, name: 'ClassName', parent: parent, method_list: [method])

      result = generator.get_method_invocation_code(c, method)
      expect(result).to eql('class_name.do_something(a, b)')
    end
  end

  describe '#get_block_code' do
    it 'works with no arg' do
      method = double(:method, block_params: '')

      result = generator.get_block_code(method)
      expect(result).to eql('')
    end
    it 'works with 1 arg block' do
      method = double(:method, block_params: 'a')

      result = generator.get_block_code(method)
      expect(result).to eql(' { |a| }')
    end
    it 'works with 2 args block' do
      method = double(:method, block_params: 'a, b')

      result = generator.get_block_code(method)
      expect(result).to eql(' { |a, b| }')
    end
  end

  class CannotExtractTargetClass < RSpecJumpstart::Generator
    def extract_target_class_or_module(*)
      nil
    end
  end

  describe '#write_spec' do

    it 'just works' do
      file_path = 'lib/rspec_jumpstart.rb'
      generator.write_spec(file_path)
    end

    it 'works with -f option' do
      file_path = 'lib/rspec_jumpstart.rb'
      generator.write_spec(file_path, true)
    end

    it 'works with -n option' do
      file_path = 'lib/rspec_jumpstart.rb'
      generator.write_spec(file_path, false, true)
    end

    it 'works with no target class' do
      file_path = 'lib/rspec_jumpstart.rb'
      CannotExtractTargetClass.new.write_spec(file_path, true)
    end

    it 'creates new spec with full_template' do
      FileUtils.rm_rf('tmp/spec') if File.exist?('tmp/spec')
      FileUtils.mkdir_p('tmp/spec')

      code = <<~CODE
        class Foo
          def hello; 'aaa'; end
        end
CODE
      FileUtils.mkdir_p('tmp/lib')
      File.open('tmp/lib/foo.rb', 'w') { |f| f.write(code) }

      generator.full_template = 'samples/full_template.erb'
      generator.write_spec('tmp/lib/foo.rb')
    end

    it 'appends new cases' do
      FileUtils.rm_rf('tmp/spec') if File.exist?('tmp/spec')
      FileUtils.mkdir_p('tmp/spec')

      code = <<~CODE
        class Foo
          def hello; 'aaa'; end
        end
CODE
      FileUtils.mkdir_p('tmp/lib')
      File.open('tmp/lib/foo.rb', 'w') { |f| f.write(code) }

      generator.write_spec('tmp/lib/foo.rb')

      orig_size = File.size('tmp/spec/tmp/lib/foo_spec.rb')
      expect(orig_size).to be > 0

      code2 = <<~CODE
        class Foo
          def hello; 'aaa'; end
          def bye?; true; end
        end
CODE
      File.open('tmp/lib/foo.rb', 'w') { |f| f.write(code2) }
      generator.write_spec('tmp/lib/foo.rb', true, true)
      generator.write_spec('tmp/lib/foo.rb', true)

      new_size = File.size('tmp/spec/tmp/lib/foo_spec.rb')
      expect(new_size).to be > orig_size

      code2 = <<~CODE
        class Foo
          def initialize; end
          def hello; 'aaa'; end
          def bye?; true; end
        end
CODE
      File.open('tmp/lib/foo.rb', 'w') { |f| f.write(code2) }
      generator.write_spec('tmp/lib/foo.rb', true, true)
      generator.write_spec('tmp/lib/foo.rb', true)

      final_size = File.size('tmp/spec/tmp/lib/foo_spec.rb')
      expect(final_size).to equal new_size
    end

    it 'appends new cases with delta_template' do
      FileUtils.rm_rf('tmp/spec') if File.exist?('tmp/spec')
      FileUtils.mkdir_p('tmp/spec')

      code = <<~CODE
        class Foo
          def hello; 'aaa'; end
        end
CODE
      FileUtils.mkdir_p('tmp/lib')
      File.open('tmp/lib/foo.rb', 'w') { |f| f.write(code) }

      generator.delta_template = 'sample/delta_template.erb'
      generator.write_spec('tmp/lib/foo.rb')

      code2 = <<~CODE
        class Foo
          def hello; 'aaa'; end
          def bye; 'aaa'; end
        end
CODE
      File.open('tmp/lib/foo.rb', 'w') { |f| f.write(code2) }
      generator.write_spec('tmp/lib/foo.rb', true, true)
      generator.write_spec('tmp/lib/foo.rb', true)
    end

    it 'appends new cases with namespaced delta_template and namespaced' do
      FileUtils.rm_rf('tmp/spec') if File.exist?('tmp/spec')
      FileUtils.rm_rf('tmp/lib') if File.exist?('tmp/lib')
      FileUtils.mkdir_p('tmp/spec')

      code = <<~CODE
        class Foo::Bar < Foo
          def hello; 'aaa'; end
        end
CODE
      FileUtils.mkdir_p('tmp/lib/foo')
      File.open('tmp/lib/foo/bar.rb', 'w') { |f| f.write(code) }

      generator.delta_template = 'sample/delta_template.erb'
      generator.write_spec('tmp/lib/foo/bar.rb')

      code2 = <<~CODE
        class Foo::Bar < Foo
          def hello; 'aaa'; end
          def bye; 'aaa'; end
        end
CODE

      FileUtils.rm_rf('tmp/lib') if File.exist?('tmp/lib')
      FileUtils.mkdir_p('tmp/lib/foo')
      File.open('tmp/lib/foo/bar.rb', 'w') { |f| f.write(code2) }
      generator.write_spec('tmp/lib/foo/bar.rb', true, true)
      generator.write_spec('tmp/lib/foo/bar.rb', true)
    end

    it 'works with rails models' do
      FileUtils.rm_rf('tmp/spec') if File.exist?('tmp/spec')
      FileUtils.mkdir_p('tmp/spec')

      code = <<~CODE
        class FooModel
          scope :test_scope, -> { where(nil) }
        end
CODE
      FileUtils.mkdir_p('tmp/app/models')
      File.open('tmp/app/models/foo_model.rb', 'w') { |f| f.write(code) }
      generator.write_spec('tmp/app/models/foo_model.rb', true, false, true)

      code = <<~CODE
        class FooModel
          scope :test_scope, -> { where(nil) }
          scope :test_scope1, -> { where(nil) }

          def foo
          end
        end
CODE
      File.open('tmp/app/models/foo_model.rb', 'w') { |f| f.write(code) }
      puts generator.write_spec('tmp/app/models/foo_model.rb', true, false, true)
    end

    it 'works with rails controllers' do
      FileUtils.rm_rf('tmp/spec') if File.exist?('tmp/spec')
      FileUtils.mkdir_p('tmp/spec')

      code = <<~CODE
        class FooController
        end
CODE
      FileUtils.mkdir_p('tmp/app/controllers')
      File.open('tmp/app/controllers/foo_controller.rb', 'w') { |f| f.write(code) }
      generator.write_spec('tmp/app/controllers/foo_controller.rb', true, false, true)

      code = <<~CODE
        class FooController
          def foo
          end
        end
CODE
      File.open('tmp/app/controllers/foo_controller.rb', 'w') { |f| f.write(code) }
      generator.write_spec('tmp/app/controllers/foo_controller.rb', true, false, true)
    end

    it 'works with rails helpers' do
      FileUtils.rm_rf('tmp/spec') if File.exist?('tmp/spec')
      FileUtils.mkdir_p('tmp/spec')

      code = <<~CODE
        class FooHelper
        end
CODE
      FileUtils.mkdir_p('tmp/app/helpers')
      File.open('tmp/app/helpers/foo_helper.rb', 'w') { |f| f.write(code) }
      generator.write_spec('tmp/app/helpers/foo_helper.rb', true, false, true)

      code = <<~CODE
        class FooHelper
          def foo
          end
        end
CODE
      File.open('tmp/app/helpers/foo_helper.rb', 'w') { |f| f.write(code) }
      generator.write_spec('tmp/app/helpers/foo_helper.rb', true, false, true)
    end

  end

  describe '#get_spec_path' do
    it 'works' do
      file_path = 'lib/foo/bar.rb'
      result    = generator.get_spec_path(file_path)
      expect(result).to eql('tmp/spec/foo/bar_spec.rb')
    end
    it 'works with path which starts with current dir' do
      file_path = './lib/foo/bar.rb'
      result    = generator.get_spec_path(file_path)
      expect(result).to eql('tmp/spec/foo/bar_spec.rb')
    end
  end

  describe '#to_string_value_to_require' do
    it 'works' do
      file_path = 'lib/foo/bar.rb'
      result    = generator.to_string_value_to_require(file_path)
      expect(result).to eql('foo/bar')
    end
  end

  describe '#to_string_namespaced_path' do
    it 'works' do
      file_path = 'lib/foo/bar.rb'
      result    = generator.to_string_namespaced_path(file_path)
      expect(result).to eql('Foo::')
    end

    it 'works' do
      file_path = 'lib/foo_baz/bar_bar/bar.rb'
      result    = generator.to_string_namespaced_path(file_path)
      expect(result).to eql('FooBaz::BarBar::')
    end

    it 'works' do
      file_path = 'lib/foo/foo/bar.rb'
      result    = generator.to_string_namespaced_path(file_path)
      expect(result).to eql('Foo::')
    end

    it 'works' do
      file_path = 'lib/bar.rb'
      result    = generator.to_string_namespaced_path(file_path)
      expect(result).to eql('')
    end
  end

  describe '#get_rails_helper_method_invocation_code' do
    it 'works' do
      method = double(:method,
                      singleton: false,
                      name:      'do_something',
                      params:    '(a, b)', block_params: '')
      result = generator.get_rails_helper_method_invocation_code(method)

      expect(result).to eql('do_something(a, b)')
    end
  end

  describe '#get_rails_http_method' do
    it 'works' do
      expect(generator.get_rails_http_method('foo')).to eql('get')
      expect(generator.get_rails_http_method('index')).to eql('get')
      expect(generator.get_rails_http_method('new')).to eql('get')
      expect(generator.get_rails_http_method('create')).to eql('post')
      expect(generator.get_rails_http_method('show')).to eql('get')
      expect(generator.get_rails_http_method('edit')).to eql('get')
      expect(generator.get_rails_http_method('update')).to eql('patch') # RAILS 4.x+
      expect(generator.get_rails_http_method('destroy')).to eql('delete')
    end
  end

end
