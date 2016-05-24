# frozen_string_literal: true
module Wakes
  module Metrics
    module GoogleAnalyticsPageviews
      extend ActiveSupport::Concern

      included do
        store_accessor :document, :pageview_count, :pageview_count_updated_through, :pageview_count_checked_at

        def enqueue_pageview_count_update
          Wakes::GoogleAnalyticsPageviewJob.perform_later(self)
        end

        def google_analytics_profile_id
          if host.blank? || (host == ENV['DEFAULT_HOST'])
            Wakes.configuration.ga_profiles['default']
          else
            Wakes.configuration.ga_profiles[host]
          end
        end

        def self.enqueue_pageview_count_updates(count)
          ordered_for_analytics_worker.needs_analytics_update.limit(count).each do |location|
            Wakes::GoogleAnalyticsPageviewJob.perform_later(location)
          end
        end

        def self.ordered_for_analytics_worker
          order("document->'pageview_count_checked_at' ASC NULLS FIRST")
        end

        def self.needs_analytics_update
          # either it's never been updated
          # OR it's canonical and it has not been updated through yesterday
          # yesterday is the most recent day it can be updated through)
          where(%{(document->>'pageview_count_updated_through') IS NULL \
                OR ("canonical" = ? AND document->>'pageview_count_updated_through' < ?)},
                true, 1.day.ago.to_date)
            .where('host IS NULL OR host = ?', [ENV['DEFAULT_HOST']]) # Only query GA for paths on the current host
        end
      end
    end
  end
end
