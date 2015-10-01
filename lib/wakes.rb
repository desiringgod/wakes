require "rails/engine"
require "wakes/version"
require "wakes/engine"

module Wakes
  def self.logger
    @logger || Rails.logger
  end

  def self.logger=(logger)
    @logger = logger
  end

  def self.table_name_prefix
    'wakes_'
  end
end
