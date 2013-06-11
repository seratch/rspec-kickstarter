# rspec-kickstarter

rspec-kickstarter supports you writing tests for existing code.

[![Build Status](https://travis-ci.org/seratch/rspec-kickstarter.png)](https://travis-ci.org/seratch/rspec-kickstarter)
[![Coverage Status](https://coveralls.io/repos/seratch/rspec-kickstarter/badge.png)](https://coveralls.io/r/seratch/rspec-kickstarter)

## RubyKaigi 2013

Lightning talk about rspec-kickstarter at RubyKaigi 2013

http://rubykaigi.org/2013/lightning_talks#seratch

https://speakerdeck.com/seratch/a-test-code-generator-for-rspec-users


## Installation

https://rubygems.org/gems/rspec-kickstarter

    gem install rspec-kickstarter

## Usage

    rspec-kickstarter ./app
    rspec-kickstarter ./lib
    rspec-kickstarter ./lib/yourapp/util.rb

## Output example

Unfortunately, `lib/foo/bar_baz.rb` has no test. That's too bad...

```ruby
module Foo
  class BarBaz

    def self.xxx(a, b = "aaa")
    end

    def yyy()
    end

    private

    def zzz(a)
    end

  end
end
```

OK, run `rspec-kickstarter` now!

```sh
$ rspec-kickstarter lib/foo/bar_baz.rb
./spec/foo/bar_baz_spec.rb created.
```

`spec/foo/bar_baz_spec.rb` will be created as follows.

```ruby
# -*- encoding: utf-8 -*-
require 'spec_helper'
require 'foo/bar_baz'

describe Foo::BarBaz do

  # TODO auto-generated
  describe 'xxx' do
    it 'works' do
      a = stub('a')
      b = stub('b')
      result = Foo::BarBaz.xxx(a, b)
      expect(result).not_to be_nil
    end
  end

  # TODO auto-generated
  describe 'yyy' do
    it 'works' do
      bar_baz = Foo::BarBaz.new
      result = bar_baz.yyy()
      expect(result).not_to be_nil
    end
  end

end
```

## Appending lacking test templates

`-f` option allows appending lacking test templates to existing specs.

For instance, `additiona_ops` method is added after spec creation.

```ruby
module Foo
  class BarBaz

    def self.xxx(a, b = "aaa")
    end

    def yyy()
    end

    def additional_ops
    end

    private

    def zzz(a)
    end

  end
end
```

Execute command.

`rspec-kickstarter -f lib/foo/bar_baz.rb`

The following code will be appended.

```ruby

  # TODO auto-generated
  describe 'additional_ops' do
    it 'works' do
      bar_baz = Foo::BarBaz.new
      result = bar_baz.additional_ops()
      expect(result).not_to be_nil
    end
  end

end
```

## Rails mode

In Rails mode, rspec-kcikstarter generates Rails way spec code for controllers and helpers.

```
$ rspec-kickstarter -r app/controllers/root_controller.rb
```

Output for scaffold:

```ruby
# -*- encoding: utf-8 -*-

require 'spec_helper'

describe CommentsController do

  # TODO auto-generated
  describe 'index' do
    it 'returns OK' do
      get :index, {}, {}
      expect(response.status).to eq(200)
    end
  end

  # TODO auto-generated
  describe 'show' do
    it 'returns OK' do
      get :show, {}, {}
      expect(response.status).to eq(200)
    end
  end

  # TODO auto-generated
  describe 'new' do
    it 'returns OK' do
      get :new, {}, {}
      expect(response.status).to eq(200)
    end
  end

  # TODO auto-generated
  describe 'edit' do
    it 'returns OK' do
      get :edit, {}, {}
      expect(response.status).to eq(200)
    end
  end

  # TODO auto-generated
  describe 'create' do
    it 'returns OK' do
      post :create, {}, {}
      expect(response.status).to eq(200)
    end
  end

  # TODO auto-generated
  describe 'update' do
    it 'returns OK' do
      put :update, {}, {}
      expect(response.status).to eq(200)
    end
  end

  # TODO auto-generated
  describe 'destroy' do
    it 'returns OK' do
      delete :destroy, {}, {}
      expect(response.status).to eq(200)
    end
  end

end
```


## Constomizable code template

See the template_samples.

```
ruby -Ilib bin/rspec-kickstarter --delta-template=samples/delta_template.erb --full-template=samples/full_template.erb lib/foo.rb -n
```

## Options

```
$ rspec-kickstarter -h
Usage: rspec-kickstarter [options]
    -f                               Create if absent or append to the existing spec
        --force
    -n                               Dry run mode (shows generated code to console)
        --dry-run
    -r                               Run in Rails mode
        --rails
    -o VAL                           Output directory (default: ./spec)
        --output-dir VAL
        --delta-template VAL         Delta template filepath
        --full-template VAL          Full template filepath
```

## License

Copyright (c) 2013 Kazuhiro Sera

MIT License

https://github.com/seratch/rspec-kickstarter/blob/master/LICENSE.txt

