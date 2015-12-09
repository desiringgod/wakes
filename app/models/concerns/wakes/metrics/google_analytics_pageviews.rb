module Wakes
  module Metrics
    module GoogleAnalyticsPageviews
      extend ActiveSupport::Concern

      included do
        store_accessor :document, :pageview_count, :pageview_count_updated_through, :pageview_count_checked_at

        def self.enqueue_pageview_count_updates(count)
          ordered_for_analytics_worker.needs_analytics_update.limit(count).each do |location|
            Wakes::GoogleAnalyticsPageviewJob.perform_later(location)
          end
        end

        def self.ordered_for_analytics_worker
          order("document->'pageview_count_checked_at' ASC NULLS FIRST")
        end

        def self.needs_analytics_update
          where("(document->>'pageview_count_updated_through') IS NULL \
                OR document->>'pageview_count_updated_through' < ?",
                1.day.ago.to_date)
        end
      end
    end
  end
end
