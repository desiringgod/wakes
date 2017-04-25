# frozen_string_literal: true

module Wakes
  module Metrics
    module Facebook
      extend ActiveSupport::Concern

      included do
        store_accessor :document, :facebook_count, :facebook_count_updated_at

        def enqueue_facebook_count_update
          Wakes::UpdateFacebookMetricsJob.perform_later(self)
        end

        def self.ordered_for_facebook_updates
          order("document->'facebook_count_updated_at' ASC NULLS FIRST")
        end

        def update_facebook_count(new_facebook_count)
          if new_facebook_count.to_i >= facebook_count.to_i
            update(:facebook_count => new_facebook_count.to_i, :facebook_count_updated_at => Time.zone.now)
          else
            Rails.logger.error "Received a request to update facebook metrics for location #{path}, " \
                              "from #{facebook_count.to_i} to #{new_facebook_count.to_i}. Ignoring it!"
          end
        end
      end
    end
  end
end
