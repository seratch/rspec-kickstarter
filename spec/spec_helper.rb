require 'simplecov'

if ENV['TRAVIS']
  require 'coveralls'
  Coveralls.wear!
else
  SimpleCov.start
end

# RSpec.configure do |config|
# end

