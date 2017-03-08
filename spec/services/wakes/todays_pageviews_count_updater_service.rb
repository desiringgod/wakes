# frozen_string_literal: true
require 'rails_helper'

RSpec.describe Wakes::TodaysPageviewsCountUpdaterService do
  let!(:wakeable_class) do
    custom_wakeable_class do
      wakes do
        run_if { false }
      end
    end
  end
  let(:wakeable) { wakeable_class.new }
  let(:resource1) { create(:resource, :wakeable => wakeable) }
  let(:resource2) { create(:resource) }

  let(:path_counts) do
    {
      resource1.locations[0].path => 100,
      resource1.locations[1].path => 12,
      resource2.locations[1].path => 62,
      resource2.locations[0].path => 2,
      resource1.locations[2].path => 33
    }
  end
  let(:path_counts2) { {} }
  let(:service) { double('GetPathCountsForDateRangeService', :path_counts => path_counts) }

  before do
    Timecop.freeze(Time.new(2016, 10, 5, 12, 0, 0))

    resource1.locations << create(:location)
    resource1.locations << create(:location, :canonical => false)
    resource1.locations << create(:location, :canonical => false)
    resource2.locations << create(:location)
    resource2.locations << create(:location, :canonical => false)

    allow(Wakes::GetPathCountsForDateRangeService).to receive(:new).and_return(service)
  end

  describe '#update_path_counts' do
    it 'creates a new GetPathCountsForDateRangeService for a date range of today' do
      expect(Wakes::GetPathCountsForDateRangeService).to receive(:new)
        .with(Date.new(2016, 10, 5)..Date.new(2016, 10, 5))
      subject.update_path_counts
    end

    it 'updates each of the locations todays pageview counts' do
      subject.update_path_counts
      path_counts.each do |path, count|
        location = Wakes::Location.find_by(:path => path)
        expect(location.todays_pageview_counts['2016-10-05']).to eq(count)
        expect(location.pageview_count).to eq(count)
      end
    end

    it 'updates the resources associated with the locations' do
      subject.update_path_counts
      resource1.reload
      resource2.reload
      expect(resource1.pageview_count).to eq(145)
      expect(resource2.pageview_count).to eq(64)
    end

    it 'updates any associated wakeables' do
      subject.update_path_counts
      resource1.reload
      expect(resource1.wakeable.pageview_count).to eq(145)
    end
  end
end
