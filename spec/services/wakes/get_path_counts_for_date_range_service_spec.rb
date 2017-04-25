# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Wakes::GetPathCountsForDateRangeService do
  describe '#path_counts' do
    subject { described_class.new(start_date..end_date) }
    let(:start_date) { Time.new(2014, 10, 10).to_date }
    let(:end_date) { Time.new(2016, 10, 10).to_date }

    let(:rows1) do
      [
        build(:page_views, :url => '/path/1', :count => 120),
        build(:page_views, :url => '/path/2', :count => 50),
        build(:page_views, :url => '/path/1?sort=newest&lang=es', :count => 12_000)
      ]
    end
    let(:rows2) do
      [
        build(:page_views, :url => '/path/1?lang=en', :count => 4001),
        build(:page_views, :url => '/path/2.html', :count => 76)
      ]
    end
    let(:page1) { double('Page', :rows => rows1, :end? => false) }
    let(:page2) { double('Page', :rows => rows2, :end? => true) }
    let(:google_analytics) { double('GoogleAnalyticsApiWrapper') }

    before do
      allow(subject).to receive(:google_analytics).and_return(google_analytics)
      allow(google_analytics).to receive(:get_page_of_pageviews).and_return(page1, page2)
    end

    it 'calls #get_page_of_pageviews until it gets the last page' do
      expect(google_analytics).to receive(:get_page_of_pageviews)
        .with(1, :start_date => start_date, :end_date => end_date).ordered
      expect(google_analytics).to receive(:get_page_of_pageviews)
        .with(2, :start_date => start_date, :end_date => end_date).ordered
      subject.path_counts
    end

    it 'returns the updated path_counts' do
      path_counts = subject.path_counts
      expect(path_counts.count).to eq(3)
      expect(path_counts['/path/1']).to eq(4121)
      expect(path_counts['/path/1?lang=es']).to eq(12_000)
      expect(path_counts['/path/2']).to eq(126)
    end

    describe 'error handling' do
      before do
        stub_const("#{described_class}::BLOCK_AFTER_ERROR_TIME", 1.second)
      end

      context 'the api request returns an error' do
        before do
          # The first time this called, it will raise an error. After that, it will return page1, then page2
          allow(google_analytics).to receive(:get_page_of_pageviews) do
            if defined?(@times_called)
              (@times_called += 1) == 2 ? page1 : page2
            else
              @times_called = 1
              raise Google::Apis::Error, 'error'
            end
          end
        end

        it 'blocks and runs the request again' do
          expect(google_analytics).to receive(:get_page_of_pageviews)
            .with(1, :start_date => start_date, :end_date => end_date).exactly(2).times
          expect(google_analytics).to receive(:get_page_of_pageviews)
            .with(2, :start_date => start_date, :end_date => end_date).once
          subject.path_counts
        end
      end
    end
  end
end
