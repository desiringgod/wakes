# frozen_string_literal: true

source 'https://rubygems.org'

ruby '2.5.0'

# Specify your gem's dependencies in wakes.gemspec
gemspec

gem 'byebug'

group :test do
  gem 'pg', '< 1' # fixed in the next rails release: https://github.com/rails/rails/pull/31671
end
