# rspec-kickstarter

rspec-kickstarter supports you writing tests for existing code.

## Installation

    gem install rspec-kickstarter

## Usage

    rspec-kickstarter ./app
    rspec-kickstarter ./lib
    rspec-kickstarter ./lib/yourapp/util.rb

## Output example

Unfortunately, `lib/foo/example.rb` has no test. That's too bad...

```ruby
module Foo
  class Example

    def self.xxx(a, b = "aaa")
    end

    def yyy()
    end

    private

    def zzz(a, b, c, d)
    end

  end
end
```

OK, run `rspec-kickstarter` now!

```sh
$ rspec-kickstarter lib/foo/example.rb
./spec/foo/example_spec.rb created.
```

`spec/foo/example_spec.rb` will be created as follows.

```ruby
# -*- encoding: utf-8 -*-
require 'spec_helper'
require 'foo/example'

describe Foo::Example do

  describe 'xxx' do
    it 'should work' do
      a = stub('a')
      b = stub('b')
      result = Foo::Example.xxx(a, b)
      # result.should_not be_nil
    end
  end

  describe 'yyy' do
    it 'should work' do
      example = Example.new
      result = example.yyy()
      # result.should_not be_nil
    end
  end

end
```

## License

MIT License

https://github.com/seratch/rspec-kickstarter/blob/master/LICENSE.txt

