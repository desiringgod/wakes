# frozen_string_literal: true
require 'rails_helper'

RSpec.describe Wakes::FacebookMetricsWrapper do
  subject { Wakes::FacebookMetricsWrapper.new(['http://www.example.com', 'http://www.example.org']) }

  # NOTE these tests will need a FACEBOOK API TOKEN when re-recording
  # Remember to remove the API TOKEN from vcr cassettes after recording!
  # before do
  #   ENV['FACEBOOK_API_TOKEN'] = '<facebook-api-token'
  # end

  describe '#share_counts' do
    it 'returns a hash of facebook share counts for the urls', :vcr do
      expect(subject.share_counts).to be_an Hash
      expect(subject.share_counts).to eq('http://www.example.com' => 14_607_817, 'http://www.example.org' => 6373)
    end

    it 'raises an exception after retrying thrice' do
      stub = stub_request(:post, api_url_with_any_parameter).and_raise(StandardError)
      expect(subject).to receive(:add_delay).twice.and_return(double)
      expect { subject.share_counts }.to raise_error(StandardError)
      expect(stub).to have_been_requested.times(3)
    end

    it 'raises an error when rate limit is exceeded' do
      allow(subject).to receive(:make_request)
        .and_return(double(:parsed_response => {'error' => {
                             'message' => 'Application request limit reached ',
                             'code' => 4,
                             'fbtrace_id' => 'randomalphnumeric'
                           }}))
      expect { subject.share_counts }.to raise_error(Wakes::FacebookMetricsWrapper::FacebookRateLimitExceeded)
    end

    it 'raises an error when Facebook returns an error response' do
      allow(subject).to receive(:make_request)
        .and_return(double(:parsed_response => {'error' => {
                             :message => 'Invalid OAuth access token signature.',
                             :type =>  'OAuthException',
                             :code =>  190,
                             :fbtrace_id => 'DPbD74EinvE'
                           }}))
      expect { subject.share_counts }.to raise_error(Wakes::FacebookMetricsWrapper::FacebookError)
    end

    it 'raises Facebook::NullResponse if one of the response is null' do
      allow(subject).to receive(:make_request)
        .and_return(double(:parsed_response => [{'body' => {'id' => 'url-1',
                                                            'shares' => {'share_counts' => 500}}.to_json},
                                                nil,
                                                nil]))
      expect { subject.share_counts }.to raise_error Wakes::FacebookMetricsWrapper::FacebookNullResponse
    end

    def api_url_with_any_parameter
      Regexp.new(Regexp.escape(api_url) + '.*')
    end

    def api_url
      Wakes::FacebookMetricsWrapper::API_URL
    end
  end
end
