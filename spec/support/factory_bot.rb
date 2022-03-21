# frozen_string_literal: true

require 'factory_bot_rails'

RSpec.configure do |config|
  config.include FactoryBot::Syntax::Methods

  config.before(:suite) do
    begin
      DatabaseCleaner.start
      FactoryBot.lint FactoryBot.factories.reject { |factory| factory.name == :page_views }
    ensure
      DatabaseCleaner.clean
    end
  end
end
