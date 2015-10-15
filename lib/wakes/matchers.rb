RSpec::Matchers.define :have_wakes_graph do |canonical_location:, legacy_locations: []|
  match do |wakes_resource|
    wakes_resource.reload

    expected_location_count = legacy_locations.size
    expected_location_count += 1 if canonical_location.present?

    wakes_resource.locations.count == expected_location_count &&
      wakes_resource.canonical_location.path == canonical_location &&
      wakes_resource.legacy_locations.pluck(:path).sort == legacy_locations.sort
  end

  failure_message do |wakes_resource|
    message = "Expected canonical location \"#{canonical_location}\", got canonical location \"#{wakes_resource.canonical_location.path}\"\n"
    message + "Expected legacy locations #{legacy_locations.sort}, got legacy locations #{wakes_resource.legacy_locations.pluck(:path).sort}"
  end
end
