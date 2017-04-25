# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Wakes::AllPageviewsCountUpdaterService do
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

  let(:path_counts1) do
    {
      resource1.locations[0].path => 562, resource1.locations[1].path => 7_120, resource2.locations[1].path => 4_500
    }
  end
  let(:path_counts2) { {resource2.locations[0].path => 9027, resource1.locations[2].path => 89} }
  let(:date_ranges) { double('DateRanges') }
  let(:date_range1) { Date.new(2015, 1, 1)..Date.new(2015, 12, 31) }
  let(:date_range2) { Date.new(2016, 1, 1)..Date.new(2016, 5, 11) }
  let(:service1) { double('GetPathCountsForDateRangeService', :path_counts => path_counts1) }
  let(:service2) { double('GetPathCountsForDateRangeService', :path_counts => path_counts2) }

  before do
    Timecop.freeze(Time.new(2016, 10, 5, 12, 0, 0))

    resource1.locations << create(:location)
    resource1.locations << create(:location, :canonical => false)
    resource1.locations << create(:location, :canonical => false)
    resource2.locations << create(:location)
    resource2.locations << create(:location, :canonical => false)

    allow(Wakes::AllPageviewsCountUpdaterService::DateRanges).to receive(:new).and_return(date_ranges)
    allow(date_ranges).to receive(:each).and_yield(date_range1).and_yield(date_range2)
    allow(Wakes::GetPathCountsForDateRangeService).to receive(:new)
      .and_return(service1, service2)
  end

  describe '#update_path_counts' do
    subject { described_class.new(2016) }

    it 'creates a new DateRanges from beginning of year to the end of year' do
      expect(Wakes::AllPageviewsCountUpdaterService::DateRanges).to(
        receive(:new).with(Date.new(2016, 1, 1)..1.day.ago.to_date, :year)
      )
      subject.update_path_counts
    end

    it 'creates a new GetPathCountsForDateRangeService for each date range' do
      expect(Wakes::GetPathCountsForDateRangeService).to receive(:new)
        .with(date_range1).ordered
      expect(Wakes::GetPathCountsForDateRangeService).to receive(:new)
        .with(date_range2).ordered
      subject.update_path_counts
    end

    context 'end year is current year' do
      subject { described_class.new(2012, 2016) }
      it 'creates a new DateRanges from beginning of the start year to yesterday' do
        expect(Wakes::AllPageviewsCountUpdaterService::DateRanges).to(
          receive(:new).with(Date.new(2012, 1, 1)..1.day.ago.to_date, :year)
        )
        subject.update_path_counts
      end
    end

    context 'end year is not current year' do
      subject { described_class.new(2011, 2013) }

      it 'creates a DateRanges from beginning of start year to the end of end year' do
        expect(Wakes::AllPageviewsCountUpdaterService::DateRanges).to(
          receive(:new).with(Date.new(2011, 1, 1)..Date.new(2013, 12, 31), :year)
        )
        subject.update_path_counts
      end
    end

    it 'updates each of the locations' do
      subject.update_path_counts
      path_counts1.merge(path_counts2).each do |path, count|
        location = Wakes::Location.find_by(:path => path)
        expect(location.pageview_counts.first[1]).to eq(count)
        expect(location.pageview_count).to eq(count)
      end
    end

    it 'updates the resources associated with the locations' do
      subject.update_path_counts
      resource1.reload
      resource2.reload
      expect(resource1.pageview_count).to eq(7771)
      expect(resource2.pageview_count).to eq(13_527)
    end

    it 'updates any associated wakeables' do
      subject.update_path_counts
      resource1.reload
      expect(resource1.wakeable.pageview_count).to eq(7771)
    end
  end
end

RSpec.describe Wakes::AllPageviewsCountUpdaterService::DateRanges do
  describe '#each' do
    def expect_next_date_range(iterator, start_date, end_date)
      range = iterator.next
      expect(range.first).to eq(start_date)
      expect(range.last).to eq(end_date)
    end

    it 'yields a range for every range period available within the given date range' do
      subject = described_class.new(Date.new(2014, 10, 9)..Date.new(2016, 4, 16), :year)
      iterator = subject.entries.each
      expect_next_date_range(iterator, Date.new(2014, 10, 9), Date.new(2014, 12, 31))
      expect_next_date_range(iterator, Date.new(2015, 1, 1), Date.new(2015, 12, 31))
      expect_next_date_range(iterator, Date.new(2016, 1, 1), Date.new(2016, 4, 16))

      subject = described_class.new(Date.new(2014, 10, 9)..Date.new(2015, 3, 12), :month)
      iterator = subject.entries.each
      expect_next_date_range(iterator, Date.new(2014, 10, 9), Date.new(2014, 10, 31))
      expect_next_date_range(iterator, Date.new(2014, 11, 1), Date.new(2014, 11, 30))
      expect_next_date_range(iterator, Date.new(2014, 12, 1), Date.new(2014, 12, 31))
      expect_next_date_range(iterator, Date.new(2015, 1, 1), Date.new(2015, 1, 31))
      expect_next_date_range(iterator, Date.new(2015, 2, 1), Date.new(2015, 2, 28))
      expect_next_date_range(iterator, Date.new(2015, 3, 1), Date.new(2015, 3, 12))
    end
  end
end
