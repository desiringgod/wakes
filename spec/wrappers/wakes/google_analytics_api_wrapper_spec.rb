# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Wakes::GoogleAnalyticsApiWrapper do
  describe '#get_page_of_pageviews' do
    let(:row1) { double('Row', dimension_values: [double('DimensionValue', value: '/resources/message-1')], metric_values: [double('MetricValue', value: 151)]) }
    let(:row2) { double('Row', dimension_values: [double('DimensionValue', value: '/resources/article-1')], metric_values: [double('MetricValue', value: 500)]) }
    let(:results) { double('Results', :rows => [row1, row2], :row_count => 2000) }
    let(:analytics_service) do
      instance_double('AnalyticsDataService', :run_property_report => results)
    end
    let(:start_date) { Time.new(2017, 10, 10).to_date }
    let(:end_date) { Time.new(2017, 12, 12).to_date }

    before do
      allow(subject).to receive(:authorized_analytics_service).and_return(analytics_service)
    end

    it 'returns a Page of data' do
      page = subject.get_page_of_pageviews(1, :start_date => start_date, :end_date => end_date)
      rows = page.rows
      expect(rows[0].url.path).to eq('/resources/message-1')
      expect(rows[0].count).to eq(151)
      expect(rows[1].url.path).to eq('/resources/article-1')
      expect(rows[1].count).to eq(500)
      expect(page).to_not be_end
    end

    context 'page is not 1' do
      it 'correctly calculates the new start index' do
        expect(subject.send(:start_index_for_page, 3)).to eq(2000)
      end
    end

    context 'total row count is less than we should expect to get by this page' do
      before { allow(results).to receive(:row_count).and_return(2) }

      it 'sets the page end to true' do
        page = subject.get_page_of_pageviews(1, :start_date => start_date, :end_date => end_date)
        expect(page).to be_end
      end
    end
  end
end

RSpec.describe Wakes::GoogleAnalyticsApiWrapper::Url do
  describe '#extension' do
    context 'extension is present' do
      subject { described_class.new('/authors/john-piper.html') }

      it 'returns the extension' do
        expect(subject.extension).to eq('html')
      end
    end

    context 'extension is not present' do
      subject { described_class.new('/authors/john-piper') }

      it 'returns nil' do
        expect(subject.extension).to be(nil)
      end
    end
  end

  describe '#lang' do
    context 'lang param is present' do
      subject { described_class.new('/authors/john-piper/messages?page=2&lang=es&sort=newest') }

      it 'returns the value' do
        expect(subject.lang).to eq('es')
      end
    end

    context 'lang param is not present' do
      subject { described_class.new('/authors/john-piper/messages?page=2&sort=newest') }

      it 'returns nil' do
        expect(subject.lang).to be(nil)
      end
    end
  end

  describe '#sanitized_path' do
    context 'params and extension not present' do
      subject { described_class.new('/authors/john-piper') }

      it 'returns the path' do
        expect(subject.sanitized_path).to eq('/authors/john-piper')
      end
    end

    context 'params not present and extension present but html' do
      subject { described_class.new('/authors/john-piper.html') }

      it 'returns the path' do
        expect(subject.sanitized_path).to eq('/authors/john-piper')
      end
    end

    context 'params not present and extension present and not html' do
      subject { described_class.new('/authors/john-piper.rss') }

      it 'returns the path with extension' do
        expect(subject.sanitized_path).to eq('/authors/john-piper.rss')
      end
    end

    context 'params present no lang and extension not present' do
      subject { described_class.new('/authors/john-piper/messages?page=2&sort=newest') }

      it 'returns the path' do
        expect(subject.sanitized_path).to eq('/authors/john-piper/messages')
      end
    end

    context 'params present with lang not en and extension not present' do
      subject { described_class.new('/authors/john-piper/messages?page=2&lang=es&sort=newest') }

      it 'returns the path with lang param' do
        expect(subject.sanitized_path).to eq('/authors/john-piper/messages?lang=es')
      end
    end

    context 'params present with lang en and extension not present' do
      subject { described_class.new('/authors/john-piper/messages?page=2&lang=en&sort=newest') }

      it 'returns the path' do
        expect(subject.sanitized_path).to eq('/authors/john-piper/messages')
      end
    end

    context 'params present with lang not en and extension present but html' do
      subject { described_class.new('/authors/john-piper/messages.html?page=2&lang=es&sort=newest') }

      it 'returns the path with lang param' do
        expect(subject.sanitized_path).to eq('/authors/john-piper/messages?lang=es')
      end
    end

    context 'params present with lang not en and extension present and not html' do
      subject { described_class.new('/authors/john-piper/messages.rss?page=2&lang=es&sort=newest') }

      it 'returns the path with lang param and extension' do
        expect(subject.sanitized_path).to eq('/authors/john-piper/messages.rss?lang=es')
      end
    end

    context 'params present with lang en and extension present but html' do
      subject { described_class.new('/authors/john-piper/messages.html?page=2&lang=en&sort=newest') }

      it 'returns the path' do
        expect(subject.sanitized_path).to eq('/authors/john-piper/messages')
      end
    end

    context 'params present with lang en and extension present and not html' do
      subject { described_class.new('/authors/john-piper/messages.rss?page=2&lang=en&sort=newest') }

      it 'returns the path with extension' do
        expect(subject.sanitized_path).to eq('/authors/john-piper/messages.rss')
      end
    end
  end
end
