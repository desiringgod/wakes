class Wakes::PageviewCountUpdaterService
  def initialize(location)
    @location = location
  end

  attr_reader :location

  def update_pageview_count
    if pageviews_since_last_update > 0
      update_location_pageview_count && update_resource_aggregate_count && update_wakeable_aggregate_count
    else
      false
    end
  ensure
    # Yes, this will often result in two update operations
    # Right now, code expressiveness and comprehension seem more important than performance
    location.update(:pageview_count_checked_at => Time.zone.now)
  end

  def update_location_pageview_count
    location.update(:pageview_count => location.pageview_count.to_i + pageviews_since_last_update,
                    :pageview_count_updated_through => end_date)
  end

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

    @pageviews ||= Wakes::GoogleAnalyticsApiWrapper.new.get_pageviews_for_path(location.path,
                                                                               :start_date => start_date,
                                                                               :end_date => end_date)
  end

  class EndDateEarlierThanStartDateError < StandardError; end;
end
