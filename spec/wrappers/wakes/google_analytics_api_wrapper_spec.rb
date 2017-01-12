# frozen_string_literal: true
require 'rails_helper'

RSpec.describe Wakes::GoogleAnalyticsApiWrapper do
  # NOTE these tests will need a Google API TOKEN to pass
  # Remember to remove the API TOKEN before committing!
  # before do
  #   ENV['GOOGLE_PRIVATE_KEY'] = '<google-private-key>'
  #   ENV['GOOGLE_CLIENT_EMAIL'] = '<google-client-email>'
  #   ENV['GOOGLE_ANALYTICS_PROFILE_ID'] = '<google-analytics-profile-id>'
  # end

  describe '#get_pageviews_for_path' do
    # Describes this view: https://www.google.com/analytics/web/?hl=en#report/content-pages/a1853263w3269662p8231065/%3F_u.date00%3D20140101%26_u.date01%3D20141231%26explorer-table.plotKeys%3D%5B%5D%26explorer-table.advFilter%3D%5B%5B0%2C%22analytics.pagePath%22%2C%22RE%22%2C%22%5E%2Fabout(%5C%5C%3F%7C%24)%22%2C0%5D%5D%26explorer-table.rowCount%3D100/
    it 'returns the total pageviews for the given date range, converting date input to date strings' do
      pageviews = subject.get_pageviews_for_path('/about',
                                                 :start_date => '2014-01-01T00:00:00+00:00',
                                                 :end_date => '2014-12-31T00:00:00+00:00')

      expect(pageviews).to eq 78_891
    end

    describe 'handles lang params' do
      it 'only matches if original path has lang' do
        pageviews = subject.get_pageviews_for_path('/sermons/for-his-sake-and-for-your-joy-go-low?lang=es',
                                                   :start_date => '2015-06-01',
                                                   :end_date => '2015-07-10')

        expect(pageviews).to eq 104
      end

      it 'does not match if original path does not have lang' do
        pageviews = subject.get_pageviews_for_path('/sermons/for-his-sake-and-for-your-joy-go-low',
                                                   :start_date => '2015-06-01',
                                                   :end_date => '2015-07-10')

        expect(pageviews).to eq 1114
      end
    end
  end

  describe '#get_page_of_pageviews' do
    let(:rows) { [['/path', 151], ['/path/2', 500]] }
    let(:results) { double('Results', :rows => rows, :items_per_page => 2) }
    let(:analytics_service) { double('AnalyticsService', :get_ga_data => results) }
    let(:start_date) { Time.new(2017, 10, 10).to_date }
    let(:end_date) { Time.new(2017, 12, 12).to_date }

    before do
      allow(subject).to receive(:authorized_analytics_service).and_return(analytics_service)
    end

    it 'calls #get_ga_data on GA' do
      expect(analytics_service).to receive(:get_ga_data).with(
        'ga:profile',
        '2017-10-10',
        '2017-12-12',
        'ga:pageviews',
        :dimensions => 'ga:pagePath',
        :sort => '-ga:pageviews',
        :start_index => 1
      )
      subject.get_page_of_pageviews(1, :start_date => start_date, :end_date => end_date, :profile_id => 'profile')
    end

    it 'returns a Page of data' do
      page = subject.get_page_of_pageviews(1, :start_date => start_date, :end_date => end_date)
      rows = page.rows
      expect(rows[0].url.path).to eq('/path')
      expect(rows[0].count).to eq(151)
      expect(rows[1].url.path).to eq('/path/2')
      expect(rows[1].count).to eq(500)
      expect(page).to_not be_end
    end

    context 'page is not 1' do
      it 'correctly calculates the new start index' do
        expect(analytics_service).to receive(:get_ga_data).with(
          any_args,
          a_hash_including(:start_index => 2001)
        )
        subject.get_page_of_pageviews(3, :start_date => start_date, :end_date => end_date)
      end
    end

    context 'rows size is less than items_per_page' do
      before { allow(results).to receive(:items_per_page).and_return(3) }

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

RSpec.describe Wakes::GoogleAnalyticsApiWrapper::PrepareFiltersForGAPagePath do
  describe '#filters' do
    it 'generates the required filter for a path' do
      subject = described_class.new('/blog')
      expect(subject.filters).to include('ga:pagePath=~^/blog(\\?|$)')
    end

    describe 'lang parameter sensitivity' do
      it 'appends filter to exclude lang parameter by default' do
        subject = described_class.new('/sermons/for-his-sake-and-for-your-joy-go-low?lang=es')
        expect(subject.filters).to_not end_with(';ga:pagePath!@lang=')
      end

      it 'does not exclude lang parameter if it is a part of the path' do
        subject = described_class.new('/sermons/for-his-sake-and-for-your-joy-go-low')
        expect(subject.filters).to end_with(';ga:pagePath!@lang=')
      end
    end
  end

  describe '#regexp_string_for_path' do
    let(:regexp_string) { described_class.new('/blog').regexp_string_for_path }
    subject { Regexp.new(regexp_string) }

    it 'matches /blog,' do
      is_expected.to match('/blog')
    end

    it 'matches /blog?page=1' do
      is_expected.to match('/blog?page=1')
    end

    it 'does not match /blog/posts/asdf' do
      is_expected.to_not match('/blog/posts/asdf')
    end

    # rubocop:disable Metrics/LineLength
    context 'regular expressions which are longer than 128 characters by default' do
      subject { described_class.new('/interviews/if-our-sins-are-punished-by-eternal-separation-from-god-why-did-jesus-only-have-to-suffer-momentary-separation') }

      it 'limits them to 128 characters' do
        expect(subject.regexp_string_for_path.length).to eq 128
      end

      it 'matches the url' do
        regexp = Regexp.new(subject.regexp_string_for_path)
        expect(regexp).to match '/interviews/if-our-sins-are-punished-by-eternal-separation-from-god-why-did-jesus-only-have-to-suffer-momentary-separation'
      end

      it 'replaces appropriate number of characters in the beginning part of the last segment with a .*' do
        expect(subject.regexp_string_for_path).to eq '^/interviews/.*our-sins-are-punished-by-eternal-separation-from-god-why-did-jesus-only-have-to-suffer-momentary-separation(\\?|$)'
      end
    end
    # rubocop:enable Metrics/LineLength
  end
end
