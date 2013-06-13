require 'coveralls'
Coveralls.wear!

require 'simplecov'
require 'simplecov-rcov'
SimpleCov.start
SimpleCov.formatter = SimpleCov::Formatter::RcovFormatter

RSpec.configure do |config|
  config.mock_framework = :mocha
end


