# frozen_string_literal: true

ENV['RAILS_ENV'] = 'test'

require File.expand_path('../dummy/config/environment.rb', __FILE__)

require 'rspec/rails'

Dir[File.join(File.dirname(__FILE__), 'support/**/*.rb')].sort.each { |f| require f }

require 'spree/testing_support/factories'

RSpec.configure do |config|
  config.include FactoryBot::Syntax::Methods

  config.use_transactional_fixtures = true

  config.infer_spec_type_from_file_location!

  config.filter_rails_from_backtrace!
end
