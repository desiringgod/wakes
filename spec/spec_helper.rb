# $LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
# require 'wakes'

require File.expand_path("../../spec/dummy/config/environment.rb",  __FILE__)
ActiveRecord::Migrator.migrations_paths = [File.expand_path("../../spec/dummy/db/migrate", __FILE__)]
