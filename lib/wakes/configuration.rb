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
    attr_accessor :additional_hosts_to_redirect

    def initialize
      @enabled = true
      @ga_profiles = {
        'default' => ENV['GOOGLE_ANALYTICS_PROFILE_ID']
      }
      @additional_hosts_to_redirect = []
    end

    def hosts_to_redirect
      # Including nil allows Wakes to always apply redirects with no host specified
      @additional_hosts_to_redirect + [nil]
    end
  end
end
