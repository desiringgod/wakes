require "rails/engine"
require "wakes/version"
require "wakes/engine"

module Wakes
  def self.table_name_prefix
    'wakes_'
  end
end
