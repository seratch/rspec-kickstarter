require 'simplecov'


if ENV['TRAVIS']
  require 'coveralls'
  Coveralls.wear!
else
  require 'simplecov'
  SimpleCov.start
end

RSpec.configure do |config|
  config.mock_framework = :mocha
end

