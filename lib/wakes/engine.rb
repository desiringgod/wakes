# frozen_string_literal: true

module Wakes
  class Engine < ::Rails::Engine
    # JSON does not include a date or time type.
    # Setting this to true will cause rails to automatically cast properly formatted
    # dates and times to ruby dates and times.
    require 'active_support/json/decoding'
    ActiveSupport.parse_json_times = true

    config.generators do |g|
      g.test_framework :rspec, :fixture => false
      g.fixture_replacement :factory_girl, :dir => 'spec/factories'
      g.assets false
      g.helper false
    end

    initializer :append_migrations do |app|
      unless app.root.to_s.match root.to_s
        config.paths['db/migrate'].expanded.each do |expanded_path|
          app.config.paths['db/migrate'] << expanded_path
        end
      end
    end
  end
end
