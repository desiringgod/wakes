# frozen_string_literal: true
require 'rails_helper'

class WakeableModel < ActiveRecord::Base
  include Wakeable
end

RSpec.describe Wakes do
  it 'has a version number' do
    expect(Wakes::VERSION).not_to be nil
  end

  describe 'creating and building' do
    let(:wakeable) { WakeableModel.new }

    describe '::build' do
      let(:wakes_resource) do
        Wakes.build(:label => 'Some Label',
                    :wakeable => wakeable,
                    :path => '/some/path',
                    :identifier => 'some-identifier')
      end

      it 'returns an unpersisted Wakes::Resource' do
        expect(wakes_resource).to_not be_persisted
        expect(wakes_resource.label).to eq('Some Label')
        expect(wakes_resource.wakeable).to eq(wakeable)
        expect(wakes_resource.identifier).to eq('some-identifier')
        expect(wakes_resource.locations.first.path).to eq('/some/path')
        expect(wakes_resource.locations.first.url).to eq("http://#{ENV['DEFAULT_HOST']}/some/path")
      end
    end

    describe '::create' do
      context 'with good input for default host' do
        let(:wakes_resource) do
          Wakes.create(:label => 'Some Label',
                       :wakeable => wakeable,
                       :path => '/some/path',
                       :identifier => 'some-identifier')
        end

        it 'is persisted' do
          expect(wakes_resource).to be_persisted
        end

        it 'creates the Wakes::Resource' do
          expect(wakes_resource.label).to eq('Some Label')
          expect(wakes_resource.wakeable).to eq(wakeable)
          expect(wakes_resource.identifier).to eq('some-identifier')
          expect(wakes_resource.locations.first.path).to eq('/some/path')
          expect(wakes_resource.locations.first.url).to eq("http://#{ENV['DEFAULT_HOST']}/some/path")
        end
      end

      context 'with good input for non-default host' do
        let(:wakes_resource) do
          Wakes.create(:label => 'Some Label',
                       :wakeable => wakeable,
                       :path => '/some/path',
                       :host => 'solidjoys.desiringgod.org',
                       :identifier => 'some-identifier')
        end

        it 'is persisted' do
          expect(wakes_resource).to be_persisted
        end

        it 'creates the Wakes::Resource' do
          expect(wakes_resource.label).to eq('Some Label')
          expect(wakes_resource.wakeable).to eq(wakeable)
          expect(wakes_resource.identifier).to eq('some-identifier')
          expect(wakes_resource.locations.first.path).to eq('/some/path')
          expect(wakes_resource.locations.first.url).to eq('http://solidjoys.desiringgod.org/some/path')
        end
      end

      context 'with bad input' do
        let(:wakes_resource) do
          Wakes.create(:label => 'Some Label',
                       :wakeable => wakeable,
                       :path => 'some/path',
                       :identifier => 'some-identifier')
        end

        it 'is not persisted' do
          expect(wakes_resource).to_not be_persisted
        end

        it 'has errors and is not valid' do
          expect(wakes_resource).to_not be_valid
          expect(wakes_resource.errors.count).to eq 1
        end
      end
    end

    describe '::create!' do
      context 'with good input for default host' do
        let(:wakes_resource) do
          Wakes.create!(:label => 'Some Label',
                        :wakeable => wakeable,
                        :path => '/some/path',
                        :identifier => 'some-identifier')
        end

        it 'is persisted' do
          expect(wakes_resource).to be_persisted
        end

        it 'creates the Wakes::Resource' do
          expect(wakes_resource.label).to eq('Some Label')
          expect(wakes_resource.wakeable).to eq(wakeable)
          expect(wakes_resource.identifier).to eq('some-identifier')
          expect(wakes_resource.locations.first.path).to eq('/some/path')
          expect(wakes_resource.locations.first.url).to eq("http://#{ENV['DEFAULT_HOST']}/some/path")
        end
      end

      context 'with good input for non-default host' do
        let(:wakes_resource) do
          Wakes.create!(:label => 'Some Label',
                        :wakeable => wakeable,
                        :path => '/some/path',
                        :host => 'solidjoys.desiringgod.org',
                        :identifier => 'some-identifier')
        end

        it 'is persisted' do
          expect(wakes_resource).to be_persisted
        end

        it 'creates the Wakes::Resource' do
          expect(wakes_resource.label).to eq('Some Label')
          expect(wakes_resource.wakeable).to eq(wakeable)
          expect(wakes_resource.identifier).to eq('some-identifier')
          expect(wakes_resource.locations.first.path).to eq('/some/path')
          expect(wakes_resource.locations.first.url).to eq('http://solidjoys.desiringgod.org/some/path')
        end
      end

      context 'with bad input' do
        it 'raises an error and creates no Wakes::Resource' do
          expect do
            Wakes.create!(:label => 'Some Label',
                          :wakeable => wakeable,
                          :path => 'some/path',
                          :identifier => 'some-identifier')
          end.to raise_error(ActiveRecord::RecordInvalid)

          expect(Wakes::Resource.last).to be_nil
        end
      end
    end
  end

  describe 'creating and destroying redis graph' do
    let(:resource_one) { create(:resource) }
    let!(:canonical_location_one) do
      create(:location, :path => '/canonical-location-one', :resource => resource_one)
    end
    let!(:legacy_location_one) do
      create(:location, :path => '/legacy-location-one', :canonical => false, :resource => resource_one)
    end
    let!(:legacy_location_two) do
      create(:location, :path => '/legacy-location-two', :canonical => false, :resource => resource_one)
    end

    let(:resource_two) { create(:resource) }
    let!(:canonical_location_two) do
      create(:location, :path => '/canonical-location-two', :resource => resource_two)
    end
    let!(:legacy_location_three) do
      create(:location, :path => '/legacy-location-three', :canonical => false, :resource => resource_two)
    end
    let!(:legacy_location_four) do
      create(:location, :path => '/legacy-location-four', :canonical => false, :resource => resource_two)
    end

    let(:resource_three) { create(:resource) }
    let!(:canonical_location_three) do
      create(:location, :path => '/canonical-location-three', :resource => resource_three)
    end
    let!(:legacy_location_five) do
      create(:location,
             :host => 'solidjoys.desiringgod.org',
             :path => '/legacy-location-five',
             :canonical => false,
             :resource => resource_three)
    end

    describe '::create_redis_graph' do
      before do
        # clear out anything that got set up during initialization
        Wakes::REDIS.del Wakes::REDIS.keys
        resource_one.update_attribute(:legacy_paths_in_redis, nil)
        resource_two.update_attribute(:legacy_paths_in_redis, nil)
        resource_three.update_attribute(:legacy_paths_in_redis, nil)

        Wakes.create_redis_graph
      end

      it 'stores the entire (local) wakes redirector graph into redis' do
        expect(Wakes::REDIS.get('/legacy-location-one')).to eq('/canonical-location-one')
        expect(Wakes::REDIS.get('/legacy-location-two')).to eq('/canonical-location-one')
        expect(Wakes::REDIS.get('/legacy-location-three')).to eq('/canonical-location-two')
        expect(Wakes::REDIS.get('/legacy-location-four')).to eq('/canonical-location-two')
      end

      it "doesn't store paths from other hosts in redis" do
        expect(Wakes::REDIS.get('/legacy-location-five')).to be_nil
      end
    end

    describe '::destroy_redis_graph' do
      it 'destroys the entire wakes redirector graph that is currently stored in redis' do
        Wakes.destroy_redis_graph

        resource_one.reload
        resource_two.reload
        resource_three.reload

        expect(Wakes::REDIS.get('/legacy-location-one')).to be_nil
        expect(Wakes::REDIS.get('/legacy-location-two')).to be_nil
        expect(Wakes::REDIS.get('/legacy-location-three')).to be_nil
        expect(Wakes::REDIS.get('/legacy-location-four')).to be_nil
        expect(Wakes::REDIS.get('/legacy-location-five')).to be_nil
        expect(resource_one.legacy_paths_in_redis).to be_blank
        expect(resource_two.legacy_paths_in_redis).to be_blank
        expect(resource_three.legacy_paths_in_redis).to be_blank
      end
    end
  end
end
