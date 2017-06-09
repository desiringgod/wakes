# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Wakes::ExternalRedirectMapper do
  describe 'Wakes.configuration.internal_hosts' do
    let!(:resource) { create(:resource, :label => 'Only Resource') }
    let!(:target) { create(:location, :canonical => true, :path => '/target', :resource => resource) }

    before do
      stub_request(:any, 't.co/some-url')
        .to_return(:status => [301, 'Moved Permanently'],
                   :headers => {:location => 'http://otherdomain.org/another-url'})
      stub_request(:any, 'otherdomain.org/another-url')
        .to_return(:status => [301, 'Moved Permanently'],
                   :headers => {:location => 'http://fr.mydomain.org'})
      stub_request(:any, 'fr.mydomain.org')
        .to_return(:status => [301, 'Moved Permanently'],
                   :headers => {:location => "http://www.mydomain.org/non-wakes-redirect"})
      stub_request(:any, 'www.mydomain.org/non-wakes-redirect')
        .to_return(:status => [301, 'Moved Permanently'],
                   :headers => {:location => "http://www.mydomain.org/target"})
      stub_request(:any, 'www.mydomain.org/target')

      ENV['DEFAULT_HOST'] = 'www.mydomain.org'
    end

    context 'as a regular expression' do
      before do
        Wakes.configure do |config|
          config.internal_hosts = /^([a-z0-9.\-]*[.])?mydomain\.org$/i
        end
      end

      it 'adds only external URLs to the wakes graph' do
        described_class.new('http://t.co/some-url').resource

        expect(resource).to have_wakes_graph(:canonical_location => '/target',
                                             :legacy_locations => ['t.co/some-url', 'otherdomain.org/another-url'])
      end
    end

    context 'as an array' do
      before do
        Wakes.configure do |config|
          config.internal_hosts = ['mydomain.org', 'otherdomain.org']
        end
      end

      it 'adds only external URLs to the wakes graph' do
        described_class.new('http://t.co/some-url').resource

        expect(resource).to have_wakes_graph(:canonical_location => '/target',
                                             :legacy_locations => ['t.co/some-url', 'fr.mydomain.org/'])
      end
    end

    context 'as a string' do
      before do
        Wakes.configure do |config|
          config.internal_hosts = 'fr.mydomain.org'
        end
      end

      it 'adds only external URLs to the wakes graph' do
        described_class.new('http://t.co/some-url').resource

        expect(resource).to have_wakes_graph(
          :canonical_location => '/target',
          :legacy_locations => ['t.co/some-url', 'otherdomain.org/another-url']
        )
      end
    end

    context 'unspecified' do
      before do
        Wakes.configuration = Wakes::Configuration.new # reset from any previous examples
      end
      it 'adds only external URLs to the wakes graph' do
        described_class.new('http://t.co/some-url').resource

        expect(resource).to have_wakes_graph(
          :canonical_location => '/target',
          :legacy_locations => ['t.co/some-url', 'otherdomain.org/another-url', 'fr.mydomain.org/']
        )
      end
    end
  end
end
