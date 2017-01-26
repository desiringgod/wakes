# frozen_string_literal: true
class Wakes::PageviewCountUpdaterService
  def initialize(location)
    @location = location
  end

  attr_reader :location

  def update_pageview_count
    if pageviews_since_last_update.positive?
      update_location_pageview_count && update_resource_aggregate_count && update_wakeable_aggregate_count
      # Yes, this will often result in two update operations
      # Right now, code expressiveness and comprehension seem more important than performance
      location.update(:pageview_count_checked_at => Time.zone.now)
    else
      false
    end
  end

  def update_location_pageview_count
    location.update(:pageview_count => location.pageview_count.to_i + pageviews_since_last_update,
                    :pageview_count_updated_through => end_date)
  end

  # If a resource's locations differ only by their query string, then this method will not work because
  # of the way the GA regex is working. The old code handled this case. It is not yet certain whether
  # we need wakes to handle it as well, because of how wakes stores its paths.
  #
  # This is the core of the old logic: https://gist.github.com/benhutton/c685aa1f8942553a9745
  def update_resource_aggregate_count
    resource = location.resource
    count = resource.locations.sum("COALESCE((wakes_locations.document ->> 'pageview_count')::int, 0)")
    resource.update(:pageview_count => count)
  end

  def update_wakeable_aggregate_count
    return true unless wakeable = location.resource.wakeable
    return true unless wakeable.respond_to?(:pageview_count=)

    count = wakeable.raw_aggregate_pageview_count
    wakeable.update(:pageview_count => count)
  end

  private

  # if we've updated through a particular day, then we need to use the next day as the start date
  def start_date
    updated_through + 1.day
  end

  def updated_through
    location.pageview_count_updated_through || ENV['GOOGLE_ANALYTICS_START_DATE'].to_date
  end

  def end_date
    1.day.ago.to_date
  end

  def pageviews_since_last_update
    # usually, they will be equal
    raise EndDateEarlierThanStartDateError, 'end_date is earlier than start date' if end_date < start_date

    @pageviews ||= Wakes::GoogleAnalyticsApiWrapper
                   .new
                   .get_pageviews_for_path(location.path,
                                           :start_date => start_date,
                                           :end_date => end_date,
                                           :profile_id => location.google_analytics_profile_id)
  end

  class EndDateEarlierThanStartDateError < StandardError; end;
end
