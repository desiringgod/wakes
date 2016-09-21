# frozen_string_literal: true
require 'rails_helper'

RSpec.describe Wakes::Metrics::GoogleAnalyticsPageviews do
  describe '::enqueue_pageview_count_updates' do
    it 'queues up the next batch of locations' do
      create(:location, :pageview_count_checked_at => 2.days.ago)
      location2 = create(:location, :pageview_count_checked_at => 3.day.ago)
      create(:location, :pageview_count_checked_at => 1.days.ago)
      location4 = create(:location, :pageview_count_checked_at => nil)

      expect { Wakes::Location.enqueue_pageview_count_updates(2) }
        .to have_enqueued_job(Wakes::GoogleAnalyticsPageviewJob).with(location2)
        .and have_enqueued_job(Wakes::GoogleAnalyticsPageviewJob).with(location4)
    end
  end

  describe '::ordered_for_analytics_worker' do
    it 'gives locations with no pageview count higher priority' do
      create(:location, :pageview_count_checked_at => nil)
      location2 = create(:location, :pageview_count_checked_at => 1.day.ago)
      create(:location, :pageview_count_checked_at => nil)
      expect(Wakes::Location.ordered_for_analytics_worker.to_a.last).to eq location2
    end

    it 'orders locations in chronological order of when pageview count was updated' do
      location1 = create(:location, :pageview_count_checked_at => 2.days.ago)
      location2 = create(:location, :pageview_count_checked_at => 3.day.ago)
      location3 = create(:location, :pageview_count_checked_at => 1.days.ago)
      location4 = create(:location, :pageview_count_checked_at => nil)
      expect(Wakes::Location.ordered_for_analytics_worker.to_a)
        .to eq [location4, location2, location1, location3]
    end
  end

  describe '::needs_analytics_update' do
    it 'exclude urls that were updated through yesterday' do
      location1 = create(:location, :pageview_count_updated_through => 2.days.ago)
      location2 = create(:location, :pageview_count_updated_through => 3.day.ago)
      location3 = create(:location, :pageview_count_updated_through => 1.days.ago)
      location4 = create(:location, :pageview_count_updated_through => nil)

      locations = Wakes::Location.needs_analytics_update.to_a

      expect(locations).to include(location1, location2, location4)
      expect(locations).not_to include(location3)
    end

    it 'excludes noncanonical urls that have already been updated' do
      location1 = create(:location, :canonical => true, :pageview_count_updated_through => 3.days.ago)
      location2 = create(:location, :canonical => false, :pageview_count_updated_through => 3.days.ago)
      location3 = create(:location, :canonical => true, :pageview_count_updated_through => nil)
      location4 = create(:location, :canonical => false, :pageview_count_updated_through => nil)

      locations = Wakes::Location.needs_analytics_update.to_a

      expect(locations).to include(location1, location3, location4)
      expect(locations).not_to include(location2)
    end

    it 'excludes urls on non-default domains' do
      location1 = create(:location, :canonical => true, :pageview_count_updated_through => nil)
      location2 = create(:location, :canonical => false, :pageview_count_updated_through => nil)
      location3 = create(:location,
                         :host => 'www.example.com',
                         :canonical => true,
                         :pageview_count_updated_through => nil)
      location4 = create(:location,
                         :host => 'www.example.com',
                         :canonical => false,
                         :pageview_count_updated_through => nil)

      locations = Wakes::Location.needs_analytics_update.to_a

      expect(locations).to include(location1, location2)
      expect(locations).not_to include(location3, location4)
    end
  end
end
