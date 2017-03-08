# frozen_string_literal: true
module Wakes
  module Metrics
    module GoogleAnalyticsPageviews
      extend ActiveSupport::Concern

      included do
        store_accessor :document, :pageview_counts, :todays_pageview_counts

        def google_analytics_profile_id
          if host.blank? || (host == ENV['DEFAULT_HOST'])
            Wakes.configuration.ga_profiles['default']
          else
            Wakes.configuration.ga_profiles[host]
          end
        end

        def pageview_count
          pageview_counts.sum { |_year, count| count } + todays_pageview_count
        end

        def pageview_counts
          super || self.pageview_counts = {}
        end

        def todays_pageview_count
          todays_pageview_counts[Time.zone.now.to_date.to_s] || 0
        end

        def todays_pageview_counts
          super || self.todays_pageview_counts = {}
        end
      end
    end
  end
end
