# frozen_string_literal: true

class Wakes::FacebookCountUpdaterService
  attr_reader :locations, :wrapper

  def initialize(*locations)
    @locations = locations.flatten
    @wrapper = Wakes::FacebookMetricsWrapper
  end

  def update_facebook_count
    locations.each_slice(45) do |locations_slice|
      share_counts = get_share_counts(locations_slice)
      locations_slice.each do |location|
        location.update_facebook_count(share_counts[location.url])
        location.resource.update_facebook_count
        location.resource.wakeable&.update_facebook_count
      end
    end
  end

  private

  def get_share_counts(locations_slice)
    wrapper.new(locations_slice.map(&:url)).share_counts
  end
end
