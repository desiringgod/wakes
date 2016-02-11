# frozen_string_literal: true
class Wakes::FacebookMetricsJob < ActiveJob::Base
  queue_as :wakes_metrics

  def perform(location)
    Wakes::FacebookCountUpdaterService.new(location).update_facebook_count
  end
end
