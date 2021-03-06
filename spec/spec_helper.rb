ENV["RAILS_ENV"] ||= 'local_test'

require File.expand_path("../../config/environment", __FILE__)
require 'rspec/rails'
require 'rspec/autorun'
require 'capybara/rails'
require 'capybara/poltergeist'
require 'database_cleaner'
require 'yaml'

AUTH_CREDENTIALS = YAML.load_file("#{Rails.root.to_s}/spec/auth_credentials.yml")

Capybara.javascript_driver = :poltergeist
Capybara.default_wait_time = 5

Dir[Rails.root.join("spec/support/**/*.rb")].each {|f| require f}

RSpec.configure do |config|
  config.mock_with :rspec
  config.infer_base_class_for_anonymous_controllers = true
  config.include Capybara::DSL
  config.include FactoryGirl::Syntax::Methods
  config.order = "random"

  config.use_transactional_fixtures = true

  config.before(:suite) do
    DatabaseCleaner.clean_with(:truncation)
  end

  config.include Requests::JsonHelpers, type: :request

  # config.before(:all) do
  #   DatabaseCleaner.clean_with(:truncation)
  # end

  # config.before(:each) do
  #   DatabaseCleaner.strategy = :transaction
  # end

  # config.before(:each, :js => true) do
  #   DatabaseCleaner.strategy = :truncation
  # end

  # config.before(:each) do
  #   DatabaseCleaner.start
  # end

  # config.after(:each) do
  #   DatabaseCleaner.clean
  # end
end
