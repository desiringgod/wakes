class Wakes::GoogleAnalyticsPageviewJob < ActiveJob::Base
  queue_as :wakes_metrics

  def perform(location)
    Wakes::PageviewCountUpdaterService.new(location).update_pageview_count
  end
end
