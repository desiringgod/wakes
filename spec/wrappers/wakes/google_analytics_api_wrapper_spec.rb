require 'rails_helper'

RSpec.describe Wakes::GoogleAnalyticsApiWrapper do
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

  describe 'error handling' do
    before do
      expect_any_instance_of(Wakes::GoogleAnalyticsApiWrapper).to receive(:authenticate!) # skip authentication
    end

    def mock_error_message(wrapper, message)
      error_double = double(:execute! => double(:error? => true, :error_message => message))
      expect(wrapper).to receive(:client).once.and_return(error_double)
    end

    describe 'daily rate limit' do
      it 'tries once and raises, meaning no retry' do
        mock_error_message(subject, 'Daily Limit Exceeded')
        expect do
          subject.send(:execute, nil)
        end.to raise_error(Wakes::GoogleAnalyticsApiWrapper::DailyLimitExceededError)
      end
    end

    describe 'user concurrency limit' do
      it 'tries once and raises, meaning no retry' do
        mock_error_message(subject, 'User Rate Limit Exceeded')
        expect do
          subject.send(:execute, nil)
        end.to raise_error(Wakes::GoogleAnalyticsApiWrapper::UserRateLimitExceededError)
      end
    end

    describe 'internal error' do
      it 'tries three times, and still raises, meaning the retry block is working' do
        mock_error_message(subject, 'There was an internal error')
        expect { subject.send(:execute, nil) }.to raise_error(Wakes::GoogleAnalyticsApiWrapper::InternalError)
      end
    end

    describe 'temporary error' do
      it 'tries three times, and still raises, meaning the retry block is working' do
        mock_error_message(subject, 'There was a temporary error. Please try again later.')
        expect { subject.send(:execute, nil) }.to raise_error(Wakes::GoogleAnalyticsApiWrapper::TemporaryError)
      end
    end

    describe 'other error' do
      it 'tries once and raises, meaning no retry' do
        mock_error_message(subject, 'Some Other Error')
        expect { subject.send(:execute, nil) }.to raise_error(RuntimeError).with_message('Some Other Error')
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
