# frozen_string_literal: true

module Wakes
  class << self
    attr_writer :configuration
  end

  def self.configuration
    @configuration ||= Configuration.new
  end

  def self.configure
    yield(configuration)
  end

  class Configuration
    attr_accessor :enabled
    attr_accessor :ga_profiles

    def initialize
      @enabled = true
      @ga_profiles = {
        'default' => ENV['GOOGLE_ANALYTICS_PROFILE_ID']
      }
    end
  end
end
