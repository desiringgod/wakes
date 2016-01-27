# frozen_string_literal: true
require 'rails_helper'

RSpec.describe Wakes::Redirectors do
  let(:resource) { create(:resource) }
  let!(:canonical_location) { create(:location, :path => '/canonical-location', :resource => resource) }
  let!(:legacy_location_one) do
    create(:location, :path => '/legacy-location-one', :canonical => false, :resource => resource)
  end
  let!(:legacy_location_two) do
    create(:location, :path => '/legacy-location-two', :canonical => false, :resource => resource)
  end

  describe 'triggering rebuild' do
    it 'is triggered by Wakes::Location create' do
      create(:location, :path => '/legacy-location-three', :canonical => false, :resource => resource)

      expect(Wakes::REDIS.get('/legacy-location-one')).to eq('/canonical-location')
      expect(Wakes::REDIS.get('/legacy-location-two')).to eq('/canonical-location')
      expect(Wakes::REDIS.get('/legacy-location-three')).to eq('/canonical-location')
      expect(resource.legacy_paths_in_redis)
        .to include('/legacy-location-one', '/legacy-location-two', '/legacy-location-three')
    end

    it 'is triggered by Wakes::Location update' do
      legacy_location_one.path = '/legacy-location-one-new'
      legacy_location_one.save!

      expect(Wakes::REDIS.get('/legacy-location-one-new')).to eq('/canonical-location')
      expect(Wakes::REDIS.get('/legacy-location-two')).to eq('/canonical-location')
      expect(resource.legacy_paths_in_redis).to include('/legacy-location-one-new', '/legacy-location-two')
    end

    it 'is triggered by Wakes::Location destroy' do
      legacy_location_one.destroy!

      expect(Wakes::REDIS.get('/legacy-location-one')).to be_nil
      expect(Wakes::REDIS.get('/legacy-location-two')).to eq('/canonical-location')
      expect(resource.legacy_paths_in_redis).to include('/legacy-location-two')
    end
  end

  describe '#create_redirect_graph' do
    before do
      # clear out anything that got set up during initialization
      Wakes::REDIS.del('/legacy-location-one', '/legacy-location-two')
      resource.update_attribute(:legacy_paths_in_redis, nil)
    end

    it 'uses the legacy paths as redis keys, mapped to the canonical path as the value' do
      resource.create_redirect_graph

      expect(Wakes::REDIS.get('/legacy-location-one')).to eq('/canonical-location')
      expect(Wakes::REDIS.get('/legacy-location-two')).to eq('/canonical-location')
    end

    it 'stores the list of legacy paths set in the Wakes::Resource' do
      resource.create_redirect_graph

      resource.reload
      expect(resource.legacy_paths_in_redis).to include('/legacy-location-one', '/legacy-location-two')
    end
  end

  before do
    # clear out anything that got set up during initialization
    Wakes::REDIS.del('/legacy-location-one', '/legacy-location-two')
    resource.update_attribute(:legacy_paths_in_redis, nil)

    # set up the graph
    resource.create_redirect_graph
    resource.reload
  end

  describe '#destroy_redirect_graph' do
    it 'destroys the redis keys corresponding to the list of legacy paths set in Wakes::Resource' do
      resource.destroy_redirect_graph

      expect(Wakes::REDIS.get('/legacy-location-one')).to be_nil
      expect(Wakes::REDIS.get('/legacy-location-two')).to be_nil
    end
    it 'nils out the list of legacy paths set in the Wakes::Resource' do
      resource.destroy_redirect_graph

      resource.reload
      expect(resource.legacy_paths_in_redis).to be_blank
    end
  end
end
