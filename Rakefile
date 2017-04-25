# frozen_string_literal: true

require 'bundler/setup'
require 'bundler/gem_tasks'
require 'rspec/core/rake_task'

RSpec::Core::RakeTask.new(:spec)

load 'rails/tasks/statistics.rake'

task :reset_db => ['app:db:drop', 'app:db:create', 'app:db:migrate', 'app:db:test:prepare']

task :default => :spec
