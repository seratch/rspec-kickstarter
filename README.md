# rspec-kickstarter

rspec-kickstarter supports you writing tests for existing code.

[![Build Status](https://travis-ci.org/seratch/rspec-kickstarter.png)](https://travis-ci.org/seratch/rspec-kickstarter)

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
      result.should_not be_nil
    end
  end

  # TODO auto-generated
  describe 'yyy' do
    it 'works' do
      bar_baz = Foo::BarBaz.new
      result = bar_baz.yyy()
      result.should_not be_nil
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
      result.should_not be_nil
    end
  end

end
```

## Options

```
$ rspec-kickstarter -h
Usage: rspec-kickstarter [options]
    -f                               Create if absent or append to the existing spec
    -n                               Dry run mode (shows generated code to console)
    -o VAL                           Output directory (default: ./spec)
```

## License

MIT License

https://github.com/seratch/rspec-kickstarter/blob/master/LICENSE.txt

