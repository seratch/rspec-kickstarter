# -*- encoding: utf-8 -*-
require 'spec_helper'
require 'rspec_kickstarter/generator'

describe RSpecKickstarter::Generator do

  let(:generator) { RSpecKickstarter::Generator.new }

  describe 'new' do
    it 'should work without params' do
      result = RSpecKickstarter::Generator.new()
      result.should_not be_nil
    end
    it 'should work' do
      spec_dir = './spec'
      result = RSpecKickstarter::Generator.new(spec_dir)
      result.should_not be_nil
    end
  end

  describe 'get_target' do
    it 'should work' do
      class1 = "Class1"
      top_level = stub(:top_level)
      top_level.stubs(:classes).returns([class1])
      result = generator.get_target(top_level)
      result.should eq(class1)
    end
  end

  describe 'get_complete_class_name' do
    it 'should work' do
      c = stub(:c)
      parent = stub(:parent)
      parent.stubs(:name).returns("Foo")
      c.stubs(:parent).returns(parent)
      name = "ClassName"
      result = generator.get_complete_class_name(c, name)
      result.should eq("ClassName")
    end
  end

  describe 'instance_name' do
    it 'should work' do
      c = stub(:c)
      c.stubs(:name).returns("generator")
      result = generator.instance_name(c)
      result.should eq("generator")
    end
  end

  describe 'to_param_names_array' do
    it 'should work' do
      params = "(a, b = 'foo', c = 123)"
      result = generator.to_param_names_array(params)
      result.should eq(['a', 'b', 'c'])
    end
  end

  describe 'get_params_initialization_code' do
    it 'should work' do
      method = stub(:method)
      method.stubs(:params).returns("(a = 1,b = 'aaaa')")
      result = generator.get_params_initialization_code(method)
      result.should eq("\n      a = stub('a')\n      b = stub('b')")
    end
  end

  describe 'get_instantiation_code' do
    it 'should work with modules' do
      c = stub(:c)
      c.stubs(:name).returns("Foo")
      method = stub(:method)
      method.stubs(:singleton).returns(true)
      method.stubs(:name).returns("to_something")
      c.stubs(:method_list).returns([method])
      result = generator.get_instantiation_code(c, method)
      result.should eq("")
    end
    it 'should work with classes' do
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
      result.should eq("\n      foo = Foo.new")
    end
  end

  describe 'get_method_invocation_code' do
    it 'should work with modules' do
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
      result.should eq("Module.to_something(a, b)")
    end
    it 'should work with classes' do
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
      result.should eq("class_name.to_something(a, b)")
    end
  end

  describe 'get_block_code' do
    it 'should work with no arg' do
      method = stub(:method)
      method.stubs(:block_params).returns("")
      result = generator.get_block_code(method)
      result.should eq("")
    end
    it 'should work with 1 arg block' do
      method = stub(:method)
      method.stubs(:block_params).returns("a")
      result = generator.get_block_code(method)
      result.should eq(" { |a| }")
    end
    it 'should work with 2 args block' do
      method = stub(:method)
      method.stubs(:block_params).returns("a, b")
      result = generator.get_block_code(method)
      result.should eq(" { |a, b| }")
    end
  end

  describe 'write_spec' do
    it 'should work' do
      file_path = "lib/rspec_kickstarter.rb"
      generator.write_spec(file_path)
    end
    it 'should work with -f option' do
      file_path = "lib/rspec_kickstarter.rb"
      generator.write_spec(file_path, true)
    end
  end

end
