# -*- encoding: utf-8 -*-
require 'spec_helper'
require 'rspec_kickstarter/generator'

describe RSpecKickstarter::Generator do

  let(:generator) { RSpecKickstarter::Generator.new("tmp/spec") }

  describe '#new' do
    it 'works without params' do
      result = RSpecKickstarter::Generator.new
      expect(result).not_to be_nil
    end
    it 'works' do
      spec_dir = './spec'
      result = RSpecKickstarter::Generator.new(spec_dir)
      expect(result).not_to be_nil
    end
  end

  describe '#get_complete_class_name' do
    it 'works' do
      c = stub(:c)
      parent = stub(:parent)
      parent.stubs(:name).returns("Foo")
      c.stubs(:parent).returns(parent)
      name = "ClassName"
      result = generator.get_complete_class_name(c, name)
      expect(result).to eq("ClassName")
    end
  end

  describe '#instance_name' do
    it 'works' do
      c = stub(:c)
      c.stubs(:name).returns("generator")
      result = generator.instance_name(c)
      expect(result).to eq("generator")
    end
  end

  describe '#to_param_names_array' do
    it 'works' do
      params = "(a, b = 'foo', c = 123)"
      result = generator.to_param_names_array(params)
      expect(result).to eq(['a', 'b', 'c'])
    end
  end

  describe '#get_params_initialization_code' do
    it 'works' do
      method = stub(:method)
      method.stubs(:params).returns("(a = 1,b = 'aaaa')")
      result = generator.get_params_initialization_code(method)
      expect(result).to eq("      a = stub('a')\n      b = stub('b')\n")
    end
  end

  describe '#get_instantiation_code' do
    it 'works with modules' do
      c = stub(:c)
      c.stubs(:name).returns("Foo")
      method = stub(:method)
      method.stubs(:singleton).returns(true)
      method.stubs(:name).returns("to_something")
      c.stubs(:method_list).returns([method])
      result = generator.get_instantiation_code(c, method)
      expect(result).to eq("")
    end
    it 'works with classes' do
      c = stub(:c)
      c.stubs(:name).returns("Foo")
      parent = stub(:parent)
      parent.stubs(:name).returns(nil)
      c.stubs(:parent).returns(parent)
      method = stub(:method)
      method.stubs(:singleton).returns(false)
      method.stubs(:name).returns("to_something")
      c.stubs(:method_list).returns([method])
      result = generator.get_instantiation_code(c, method)
      expect(result).to eq("      foo = Foo.new\n")
    end
  end

  describe '#get_method_invocation_code' do
    it 'works with modules' do
      c = stub(:c)
      c.stubs(:name).returns("Module")
      parent = stub(:parent)
      parent.stubs(:name).returns(nil)
      c.stubs(:parent).returns(parent)
      method = stub(:method)
      method.stubs(:singleton).returns(true)
      method.stubs(:name).returns("to_something")
      method.stubs(:params).returns("(a, b)")
      method.stubs(:block_params).returns("")
      result = generator.get_method_invocation_code(c, method)
      expect(result).to eq("Module.to_something(a, b)")
    end
    it 'works with classes' do
      c = stub(:c)
      c.stubs(:name).returns("ClassName")
      parent = stub(:parent)
      parent.stubs(:name).returns(nil)
      c.stubs(:parent).returns(parent)
      method = stub(:method)
      method.stubs(:singleton).returns(false)
      method.stubs(:name).returns("to_something")
      method.stubs(:params).returns("(a, b)")
      method.stubs(:block_params).returns("")
      result = generator.get_method_invocation_code(c, method)
      expect(result).to eq("class_name.to_something(a, b)")
    end
  end

  describe '#get_block_code' do
    it 'works with no arg' do
      method = stub(:method)
      method.stubs(:block_params).returns("")
      result = generator.get_block_code(method)
      expect(result).to eq("")
    end
    it 'works with 1 arg block' do
      method = stub(:method)
      method.stubs(:block_params).returns("a")
      result = generator.get_block_code(method)
      expect(result).to eq(" { |a| }")
    end
    it 'works with 2 args block' do
      method = stub(:method)
      method.stubs(:block_params).returns("a, b")
      result = generator.get_block_code(method)
      expect(result).to eq(" { |a, b| }")
    end
  end

  class CannotExtractTargetClass < RSpecKickstarter::Generator
    def extract_target_class_or_module(top_level)
      nil
    end
  end

  describe '#write_spec' do

    it 'just works' do
      file_path = "lib/rspec_kickstarter.rb"
      generator.write_spec(file_path)
    end

    it 'works with -f option' do
      file_path = "lib/rspec_kickstarter.rb"
      generator.write_spec(file_path, true)
    end

    it 'works with -n option' do
      file_path = "lib/rspec_kickstarter.rb"
      generator.write_spec(file_path, false, true)
    end

    it 'works with no target class' do
      file_path = "lib/rspec_kickstarter.rb"
      CannotExtractTargetClass.new.write_spec(file_path, true)
    end

    it 'creates new spec with full_tempalte' do
      FileUtils.rm_rf('tmp/spec') if File.exist?('tmp/spec')
      FileUtils.mkdir_p('tmp/spec')

      code = <<CODE
class Foo
  def hello; "aaa"; end
end
CODE
      FileUtils.mkdir_p('tmp/lib')
      File.open('tmp/lib/foo.rb', 'w') { |f| f.write(code) }

      generator.full_template = "samples/full_template.erb"
      generator.write_spec('tmp/lib/foo.rb')
    end

    it 'appends new cases' do
      FileUtils.rm_rf('tmp/spec') if File.exist?('tmp/spec')
      FileUtils.mkdir_p('tmp/spec')

      code = <<CODE
class Foo
  def hello; "aaa"; end
end
CODE
      FileUtils.mkdir_p('tmp/lib')
      File.open('tmp/lib/foo.rb', 'w') { |f| f.write(code) }

      generator.write_spec('tmp/lib/foo.rb')

      code2 = <<CODE
class Foo
  def hello; "aaa"; end
  def bye; "aaa"; end
end
CODE
      File.open('tmp/lib/foo.rb', 'w') { |f| f.write(code2) }
      generator.write_spec("tmp/lib/foo.rb", true, true)
      generator.write_spec("tmp/lib/foo.rb", true)
    end

    it 'appends new cases with delta_template' do
      FileUtils.rm_rf('tmp/spec') if File.exist?('tmp/spec')
      FileUtils.mkdir_p('tmp/spec')

      code = <<CODE
class Foo
  def hello; "aaa"; end
end
CODE
      FileUtils.mkdir_p('tmp/lib')
      File.open('tmp/lib/foo.rb', 'w') { |f| f.write(code) }

      generator.delta_template = "sample/delta_template.erb"
      generator.write_spec('tmp/lib/foo.rb')

      code2 = <<CODE
class Foo
  def hello; "aaa"; end
  def bye; "aaa"; end
end
CODE
      File.open('tmp/lib/foo.rb', 'w') { |f| f.write(code2) }
      generator.write_spec("tmp/lib/foo.rb", true, true)
      generator.write_spec("tmp/lib/foo.rb", true)
    end

    it 'works with rails controllers' do 
      FileUtils.rm_rf('tmp/spec') if File.exist?('tmp/spec')
      FileUtils.mkdir_p('tmp/spec')

      code = <<CODE
class FooController
end
CODE
      FileUtils.mkdir_p('tmp/app/controllers')
      File.open('tmp/app/controllers/foo_controller.rb', 'w') { |f| f.write(code) }
      generator.write_spec('tmp/app/controllers/foo_controller.rb', true, false, true)

      code = <<CODE
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

      code = <<CODE
class FooHelper
end
CODE
      FileUtils.mkdir_p('tmp/app/helpers')
      File.open('tmp/app/helpers/foo_helper.rb', 'w') { |f| f.write(code) }
      generator.write_spec('tmp/app/helpers/foo_helper.rb', true, false, true)

      code = <<CODE
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
      result = generator.get_spec_path(file_path)
      expect(result).to eq('tmp/spec/foo/bar_spec.rb')
    end
    it 'works with path which starts with current dir' do
      file_path = './lib/foo/bar.rb'
      result = generator.get_spec_path(file_path)
      expect(result).to eq('tmp/spec/foo/bar_spec.rb')
    end
  end

  describe '#to_string_value_to_require' do
    it 'works' do
      file_path = 'lib/foo/bar.rb'
      result = generator.to_string_value_to_require(file_path)
      expect(result).to eq('foo/bar')
    end
  end


  describe '#get_rails_helper_method_invocation_code' do
    it 'works' do
      c = stub(:c)
      c.stubs(:name).returns("ClassName")
      parent = stub(:parent)
      parent.stubs(:name).returns(nil)
      c.stubs(:parent).returns(parent)
      method = stub(:method)
      method.stubs(:singleton).returns(false)
      method.stubs(:name).returns("to_something")
      method.stubs(:params).returns("(a, b)")
      method.stubs(:block_params).returns("")
      result = generator.get_rails_helper_method_invocation_code(method)
      expect(result).to eq("to_something(a, b)")
    end
  end

  describe '#get_rails_http_method' do
    it 'works' do
      expect(generator.get_rails_http_method('foo')).to eq('get')
      expect(generator.get_rails_http_method('index')).to eq('get')
      expect(generator.get_rails_http_method('new')).to eq('get')
      expect(generator.get_rails_http_method('create')).to eq('post')
      expect(generator.get_rails_http_method('show')).to eq('get')
      expect(generator.get_rails_http_method('edit')).to eq('get')
      expect(generator.get_rails_http_method('update')).to eq('put')
      expect(generator.get_rails_http_method('destroy')).to eq('delete')
    end
  end

end
