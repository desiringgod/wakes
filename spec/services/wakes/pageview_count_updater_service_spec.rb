# frozen_string_literal: true
require 'rails_helper'

RSpec.describe Wakes::PageviewCountUpdaterService do
  describe '#update_pageview_count' do
    let(:location) { create(:location, :resource => resource) }
    let(:location_2) { create(:location, :resource => resource, :canonical => false) }
    let(:pageview_count_updater_service) { Wakes::PageviewCountUpdaterService.new(location) }
    let(:pageview_count_updater_service_2) { Wakes::PageviewCountUpdaterService.new(location_2) }

    before do
      Timecop.freeze
    end

    describe 'no wakeable present' do
      let(:resource) { create(:resource) }

      it 'updates pageviews on the location' do
        allow(pageview_count_updater_service).to receive(:pageviews_since_last_update).and_return(1200)
        expect(pageview_count_updater_service.update_pageview_count).to eq true
        expect(location.pageview_count).to eq 1200
        expect(location.resource.pageview_count).to eq 1200
        expect(location.pageview_count_updated_through).to eq Date.yesterday
        expect(location.pageview_count_checked_at).to be_within(0.1).of(Time.zone.now)
      end

      it 'stores the sum of location pageviews in the resource' do
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
        expect(location.pageview_count_checked_at).to be_within(0.1).of(Time.zone.now)
      end

      it 'returns a false if pageviews_since_last_update are negative for some odd reason' do
        allow(pageview_count_updater_service).to receive(:pageviews_since_last_update).and_return(-1200)
        expect(pageview_count_updater_service.update_pageview_count).to eq false
        expect(location.pageview_count_checked_at).to be_within(0.1).of(Time.zone.now)
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
        expect(location.pageview_count_checked_at).to be_within(0.1).of(Time.zone.now)
      end
    end

    describe 'a wakeable with one wakes_resource' do
      let(:wakeable_class) do
        custom_wakeable_class do
          wakes do
            run_if { false }
          end
        end
      end

      let(:wakeable) { wakeable_class.new }
      let(:resource) { create(:resource, :wakeable => wakeable) }

      it 'stores the sum of location pageviews in the wakeable' do
        allow(pageview_count_updater_service).to receive(:pageviews_since_last_update).and_return(1200)
        expect(pageview_count_updater_service.update_pageview_count).to eq true
        expect(location.pageview_count).to eq 1200
        expect(location.resource.pageview_count).to eq 1200
        expect(location.resource.wakeable.pageview_count).to eq 1200

        allow(pageview_count_updater_service_2).to receive(:pageviews_since_last_update).and_return(12)
        expect(pageview_count_updater_service_2.update_pageview_count).to eq true
        expect(location_2.pageview_count).to eq 12
        expect(location_2.resource.pageview_count).to eq 1212
        expect(location_2.resource.wakeable.pageview_count).to eq 1212
      end
    end

    describe 'a wakeable with multiple wakes_resources' do
      let(:wakeable_class) do
        custom_wakeable_class do
          wakes do
            run_if { false }
            has_many do
              [
                {
                  :label => 'One',
                  :identifier => 'one',
                  :path_fragment => 'one'
                },
                {
                  :label => 'Two',
                  :identifier => 'two',
                  :path_fragment => 'two'
                }
              ]
            end
          end
        end
      end

      let(:wakeable) { wakeable_class.new }
      let(:resource) { create(:resource, :wakeable => wakeable) }
      let(:resource_2) { create(:resource, :wakeable => wakeable) }

      it 'stores the sum of location pageviews in the wakeable' do
        allow(pageview_count_updater_service).to receive(:pageviews_since_last_update).and_return(1200)
        expect(pageview_count_updater_service.update_pageview_count).to eq true
        expect(location.pageview_count).to eq 1200
        expect(location.resource.pageview_count).to eq 1200
        expect(location.resource.wakeable.pageview_count).to eq 1200

        allow(pageview_count_updater_service_2).to receive(:pageviews_since_last_update).and_return(12)
        expect(pageview_count_updater_service_2.update_pageview_count).to eq true
        expect(location_2.pageview_count).to eq 12
        expect(location_2.resource.pageview_count).to eq 1212
        expect(location_2.resource.wakeable.pageview_count).to eq 1212
      end
    end
  end
end
