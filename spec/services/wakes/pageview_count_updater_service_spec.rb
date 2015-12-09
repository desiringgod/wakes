require 'rails_helper'

RSpec.describe Wakes::PageviewCountUpdaterService do
  describe '#update_pageview_count' do
    let(:location) { create(:location, :path => '/articles/marriage-on-the-edge-of-eternity') }
    let(:pageview_count_updater_service) { Wakes::PageviewCountUpdaterService.new(location) }

    before do
      Timecop.freeze
    end

    it 'updates pageviews on the location' do
      allow(pageview_count_updater_service).to receive(:pageviews_since_last_update).and_return(1200)
      expect(pageview_count_updater_service.update_pageview_count).to eq true
      expect(location.pageview_count).to eq 1200
      expect(location.resource.pageview_count).to eq 1200
      expect(location.pageview_count_updated_through).to eq Date.yesterday
      expect(location.pageview_count_checked_at).to eq Time.zone.now
    end

    it 'stores the sum of location pageviews in the resource' do
      location_2 = create(:location, :resource => location.resource, :canonical => false)
      pageview_count_updater_service_2 = Wakes::PageviewCountUpdaterService.new(location_2)

      allow(pageview_count_updater_service).to receive(:pageviews_since_last_update).and_return(1200)
      expect(pageview_count_updater_service.update_pageview_count).to eq true
      expect(location.pageview_count).to eq 1200
      expect(location.resource.pageview_count).to eq 1200

      allow(pageview_count_updater_service_2).to receive(:pageviews_since_last_update).and_return(12)
      expect(pageview_count_updater_service_2.update_pageview_count).to eq true
      expect(location_2.pageview_count).to eq 12
      expect(location_2.resource.pageview_count).to eq 1212
    end

    it 'returns a false if pageviews_since_last_update are 0' do
      allow(pageview_count_updater_service).to receive(:pageviews_since_last_update).and_return(0)
      expect(pageview_count_updater_service.update_pageview_count).to eq false
      expect(location.pageview_count_checked_at).to eq Time.zone.now
    end

    it 'returns a false if pageviews_since_last_update are negative for some odd reason' do
      allow(pageview_count_updater_service).to receive(:pageviews_since_last_update).and_return(-1200)
      expect(pageview_count_updater_service.update_pageview_count).to eq false
      expect(location.pageview_count_checked_at).to eq Time.zone.now
    end

    it 'raises an error if end date becomes larger than start date' do
      location.update(:pageview_count_updated_through => Date.yesterday)
      expect do
        pageview_count_updater_service.update_pageview_count
      end.to raise_error(Wakes::PageviewCountUpdaterService::EndDateEarlierThanStartDateError)
    end

    it 'always rescues, updates date, and then reraises if there is an error' do
      allow(pageview_count_updater_service).to receive(:pageviews_since_last_update).and_raise(StandardError)

      expect { pageview_count_updater_service.update_pageview_count }.to raise_error(StandardError)
      expect(location.pageview_count_checked_at).to eq Time.zone.now
    end
  end
end
