# frozen_string_literal: true
class Wakes::FacebookCountUpdaterService
  attr_reader :location, :resource, :wrapper

  def initialize(location)
    @location = location
    @resource = location.resource
    @wrapper = Wakes::FacebookMetricsWrapper.new(location.url)
  end

  def update_facebook_count
    location.update(:facebook_count => wrapper.total_count)
    resource.update(:facebook_count => aggregated_facebook_counts)
  end

  private

  def aggregated_facebook_counts
    resource.locations.sum("COALESCE((wakes_locations.document ->> 'facebook_count')::int, 0)")
  end
end
