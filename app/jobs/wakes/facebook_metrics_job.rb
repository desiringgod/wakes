# frozen_string_literal: true
class Wakes::FacebookMetricsJob < ActiveJob::Base
  queue_as :wakes_metrics

  def perform(locations)
    Wakes::FacebookCountUpdaterService.new(locations).update_facebook_count
  end
end
