# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Wakes::Location, :type => :model do
  describe '#path' do
    it 'must begin with a slash (/)' do
      expect(build(:location, :path => 'some/path')).to_not be_valid
      expect(build(:location, :path => '/some/path')).to be_valid
    end

    it 'must be unique' do
      expect(create(:location, :path => '/some/path')).to be_valid
      expect(build(:location, :path => '/some/path')).to_not be_valid
    end

    it 'does not consider as equivalent identical paths on different hosts' do
      expect(create(:location, :path => '/some/path', :host => 'www.desiringgod.org')).to be_valid
      expect(build(:location, :path => '/some/path', :host => 'solidjoys.desiringgod.org')).to be_valid
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
      expect(location.url(:host_override => 'awesome.domain')).to include('awesome.domain')
    end

    it 'picks the host from wakes location if no argument is passed' do
      location.host = 'awesome.domain'
      expect(location.url).to include('awesome.domain')
    end

    it 'defaults to the DEFAULT_HOST environment variable if location not otherwise specified' do
      previous_value = ENV['DEFAULT_HOST']
      ENV['DEFAULT_HOST'] = 'default.host'

      expect(location.url).to include('default.host')

      ENV['DEFAULT_HOST'] = previous_value
    end

    it 'picks the protocol from the protocol argument passed to it' do
      expect(location.url(:protocol => 'ftp')).to start_with('ftp://')
    end

    it 'defaults to the https protocol' do
      expect(location.url).to start_with('https://')
    end
  end

  describe '#update_facebook_count' do
    subject(:location) { create(:location, :facebook_count => 100) }
    before { Timecop.freeze(2017, 0o4, 25) }

    context 'when count is greater than the current count' do
      before { location.update_facebook_count(101) }

      it 'updates facebook_count' do
        expect(location.facebook_count).to eq 101
      end

      it 'updates facebook_count_updated_at' do
        expect(location.facebook_count_updated_at).to eq(Time.zone.now)
      end
    end

    context 'when count is equal to the current count' do
      before { location.update_facebook_count(100) }

      it 'updates facebook_count' do
        expect(location.facebook_count).to eq 100
      end

      it 'updates facebook_count_updated_at' do
        expect(location.facebook_count_updated_at).to eq(Time.zone.now)
      end
    end

    context 'when count is less than the current count' do
      before { location.update_facebook_count(99) }

      it 'does not update facebook_count' do
        expect(location.facebook_count).to eq 100
      end

      it 'does not update facebook_count_updated_at' do
        expect(location.facebook_count_updated_at).to_not eq(Time.zone.now)
      end
    end

    context 'when count is nil' do
      before { location.update_facebook_count(nil) }

      it 'does not update facebook_count' do
        expect(location.facebook_count).to eq 100
      end

      it 'does not update facebook_count_updated_at' do
        expect(location.facebook_count_updated_at).to_not eq(Time.zone.now)
      end
    end

    context 'when count is an empty string' do
      before { location.update_facebook_count('') }

      it 'does not update facebook_count' do
        expect(location.facebook_count).to eq 100
      end

      it 'does not update facebook_count_updated_at' do
        expect(location.facebook_count_updated_at).to_not eq(Time.zone.now)
      end
    end
  end
end
