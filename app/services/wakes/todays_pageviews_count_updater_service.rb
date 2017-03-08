# frozen_string_literal: true

module Wakes
  class TodaysPageviewsCountUpdaterService
    def update_path_counts
      GetPathCountsForDateRangeService.new(today_date_range).path_counts.each do |path, count|
        update_path_count(path, count)
      end
    end

    private

    def today_date_range
      today..today
    end

    def today
      @today ||= Time.zone.now.to_date
    end

    def update_path_count(path, count)
      location = Wakes::Location.where(:path => path).first
      return unless location.present?

      location.todays_pageview_counts = {today.to_s => count}
      location.save
      location.resource&.update_pageview_count
      begin
        location.resource.wakeable&.update_pageview_count
      rescue NameError => ex # Invalid wakeable
        puts ex.message
      end
    end
  end
end
