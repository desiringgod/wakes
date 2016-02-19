# frozen_string_literal: true
require 'rails_helper'

RSpec.describe Wakes::Location, :type => :model do
  describe '::find_by_url' do
    let!(:location) { create(:location, :path => '/articles') }

    it 'returns the location when the path matches the path of a location and host matches the default host' do
      using_default_host('my.host') do
        expect(described_class.find_by_url('http://my.host/articles')).to eq location
      end
    end

    it 'ignores the host if the DEFAULT_HOST environment variable is not set' do
      using_default_host(nil) do
        expect(described_class.find_by_url('http://my.host/articles')).to eq location
      end
    end

    it 'returns ActiveRecord::RecordNotFound error if path does not match' do
      using_default_host('my.host') do
        expect { described_class.find_by_url('http://another.host/articles') }
          .to raise_error Wakes::Location::HostMismatchError
      end
    end
  end

  describe '#path' do
    it 'must begin with a slash (/)' do
      expect(build(:location, :path => 'some/path')).to_not be_valid
      expect(build(:location, :path => '/some/path')).to be_valid
    end

    it 'must be unique' do
      expect(create(:location, :path => '/some/path')).to be_valid
      expect(build(:location, :path => '/some/path')).to_not be_valid
    end
  end

  it 'belongs to a resource' do
    resource = create(:resource)

    location = create(:location, :resource => resource)

    expect(location.resource).to eq(resource)
  end

  describe '#url' do
    subject(:location) { build(:location) }

    it 'returns the url generated from the path from wakes location' do
      expect(location.url).to include(location.path)
    end

    it 'picks the host from the argument passed to it' do
      expect(location.url(:host => 'awesome.domain')).to include('awesome.domain')
    end

    it 'defaults to the DEFAULT_HOST environment variable if no argument is passed to it' do
      using_default_host('default.host') do
        expect(location.url).to include('default.host')
      end
    end

    it 'picks the protocol from the protocol argument passed to it' do
      expect(location.url(:protocol => 'https')).to start_with('https://')
    end

    it 'defaults to the http protocol' do
      expect(location.url).to start_with('http://')
    end
  end

  def using_default_host(host)
    previous_value = ENV['DEFAULT_HOST']
    ENV['DEFAULT_HOST'] = host
    yield
    ENV['DEFAULT_HOST'] = previous_value
  end
end
