require 'rubygems'
require 'bundler/setup'

require 'rails/all'

module CequelMigrationsRails
  class Application < ::Rails::Application
  end
end

require 'cequel-migrations-rails'

RSpec.configure do |config|
end
