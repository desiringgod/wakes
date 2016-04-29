# frozen_string_literal: true

require_relative 'uri_from_location_string'

RSpec::Matchers.define :have_wakes_graph do |canonical_location:, legacy_locations: []|
  match do |wakes_resource|
    wakes_resource.reload

    expected_location_count = legacy_locations.size
    expected_location_count += 1 if canonical_location.present?

    wakes_resource.locations.count == expected_location_count &&
      wakes_resource.canonical_location.host == URIFromLocationString.generate(canonical_location).host &&
      wakes_resource.canonical_location.path == URIFromLocationString.generate(canonical_location).request_uri &&
      wakes_resource.legacy_locations.pluck(:host, :path).sort ==
        legacy_locations.map { |x| URIFromLocationString.get_host_and_path(x) }.sort
  end

  failure_message do |wakes_resource|
    legacy_locations_array = legacy_locations.map { |x| URIFromLocationString.get_host_and_path(x) }.sort
    message = "Expected canonical location \"#{canonical_location}\","
    message += " got canonical location \"#{wakes_resource.canonical_location.label}\"\n"
    message += "Expected legacy locations #{legacy_locations_array}, "
    message + "got legacy locations #{wakes_resource.legacy_locations.pluck(:host, :path).sort}"
  end
end
