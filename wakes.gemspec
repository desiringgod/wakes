# coding: utf-8
# frozen_string_literal: true
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'wakes/version'

Gem::Specification.new do |spec|
  spec.name          = 'wakes'
  spec.version       = Wakes::VERSION
  spec.authors       = ['Ben Hutton', 'Desiring God']
  spec.email         = ['benhutton@gmail.com', 'web@desiringgod.org']

  spec.summary       = 'A graph of Resources and Locations for use in legacy redirection and metrics aggregation'
  spec.homepage      = 'https://github.com/desiringgod/wakes'

  # Prevent pushing this gem to RubyGems.org by setting 'allowed_push_host', or
  # delete this section to allow pushing this gem to any host.
  if spec.respond_to?(:metadata)
    spec.metadata['allowed_push_host'] = "TODO: Set to 'http://mygemserver.com'"
  else
    raise 'RubyGems 2.0 or newer is required to protect against public gem pushes.'
  end

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']
  spec.test_files = Dir['spec/**/*']

  spec.add_dependency 'rails', '~> 4.2.4'
  spec.add_dependency 'google-api-client'
  spec.add_dependency 'redis-rails'
  spec.add_dependency 'redis-namespace'

  spec.add_development_dependency 'bundler'
  spec.add_development_dependency 'rake'
  spec.add_development_dependency 'rspec-rails'
  spec.add_development_dependency 'rspec_junit_formatter'
  spec.add_development_dependency 'factory_girl_rails'
  spec.add_development_dependency 'guard'
  spec.add_development_dependency 'guard-rspec'
  spec.add_development_dependency 'pg'
  spec.add_development_dependency 'database_cleaner'
  spec.add_development_dependency 'combustion'
  spec.add_development_dependency 'rubocop'
  spec.add_development_dependency 'guard-rubocop'
  spec.add_development_dependency 'timecop'
end
