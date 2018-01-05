# frozen_string_literal: true

lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'rspec_jumpstart/version'

Gem::Specification.new do |gem|
  gem.name          = 'rspec-jumpstart'
  gem.version       = RSpecJumpstart::VERSION
  gem.authors       = ['Timothy Chambers']
  gem.email         = ['tim@possibilogy.com']
  gem.licenses      = ['MIT']
  gem.description   = 'rspec-jumpstart supports you writing tests for existing code.'
  gem.summary       = 'rspec-jumpstart supports you writing tests for existing code.'
  gem.homepage      = 'https://github.com/tjchambers/rspec-jumpstart'
  gem.files         = Dir['{bin,lib}/**/*']
  gem.executables   = gem.files.grep(%r{^bin/}).map { |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ['lib']
end
