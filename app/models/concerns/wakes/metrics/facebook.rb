# frozen_string_literal: true

module Wakes
  module Metrics
    module Facebook
      extend ActiveSupport::Concern

      included do
        store_accessor :document, :facebook_count, :facebook_count_updated_at

        before_validation :prevent_update_of_legacy_location, :prevent_decreasing_update, :on => :update

        def enqueue_facebook_count_update
          Wakes::UpdateFacebookMetricsJob.perform_later(self)
        end

        def self.ordered_for_facebook_updates
          order("document->'facebook_count_updated_at' ASC NULLS FIRST")
        end

        def update_facebook_count(new_facebook_count)
          update(:facebook_count => new_facebook_count.to_i, :facebook_count_updated_at => Time.zone.now) ||
            restore_attributes
        end

        protected

        def prevent_update_of_legacy_location
          if facebook_count_will_change? && !canonical
            Rails.logger.error 'Received a request to update facebook metrics for non-canonical location ' \
                              "#{path}, from #{old_count} to #{new_count}. Ignoring it!"
            throw :abort
          end
        end

        def prevent_decreasing_update
          if new_count < old_count
            Rails.logger.error 'Received a request to update facebook metrics for location ' \
                              "#{path}, from #{old_count} to #{new_count}. Ignoring it!"
            throw :abort
          end
        end

        def old_count
          changes[:document]&.first.try(:[], :facebook_count).to_i
        end

        def new_count
          changes[:document]&.second.try(:[], :facebook_count).to_i
        end

        # from https://github.com/rails/rails/issues/16808#issuecomment-112264052
        def facebook_count_will_change?
          changes[:document] && changes[:document].map { |v| v.try(:[], :facebook_count) }.uniq.length > 1
        end
      end
    end
  end
end
