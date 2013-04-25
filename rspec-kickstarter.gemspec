# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'rspec_kickstarter/version'

Gem::Specification.new do |gem|
  gem.name          = "rspec-kickstarter"
  gem.version       = RSpecKickstarter::VERSION
  gem.authors       = ["Kazuhiro Sera"]
  gem.email         = ["seratch@gmail.com"],
  gem.licenses      = ["MIT"],
  gem.description   = %q{RSpec kickstarter generates spec files for existing code.}
  gem.summary       = %q{RSpec kickstarter generates spec files for existing code.}
  gem.homepage      = "https://github.com/seratch/rspec-kickstarter"

  gem.files         = Dir["{bin,lib}/**/*"]
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]
end
