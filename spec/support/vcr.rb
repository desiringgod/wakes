# frozen_string_literal: true
require 'vcr'

VCR.configure do |c|
  c.cassette_library_dir = 'spec/cassettes'
  c.hook_into :webmock
  c.configure_rspec_metadata!
  c.ignore_localhost = true
  c.default_cassette_options = { :record => :once } # this is default, but we'll set it explicitly just to be clear
  c.allow_http_connections_when_no_cassette = true
end
