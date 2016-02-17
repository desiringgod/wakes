# frozen_string_literal: true
require 'rails_helper'

RSpec.describe Wakes::Resource, :type => :model do
  it 'has a label' do
    expect(build(:resource, :label => 'Some Label').label).to eq('Some Label')
  end

  describe 'locations' do
    it 'has many locations' do
      location_one = build(:location)
      location_two = build(:location)

      resource = create(:resource, :locations => [location_one, location_two])

      expect(resource.locations).to contain_exactly(location_one, location_two)
    end

    it 'has one canonical location' do
      location_one = build(:location, :canonical => true)
      location_two = build(:location, :canonical => false)

      resource = create(:resource, :locations => [location_one, location_two])

      expect(resource.canonical_location).to eq(location_one)
    end

    it 'has many legacy locations' do
      location_one = build(:location, :canonical => true)
      location_two = build(:location, :canonical => false)
      location_three = build(:location, :canonical => false)

      resource = create(:resource, :locations => [location_one, location_two, location_three])

      resource.reload
      expect(resource.legacy_locations).to contain_exactly(location_two, location_three)
    end

    describe 'canonical locations' do
      let(:resource) { create(:resource) }

      context 'one location' do
        it 'must not be noncanonical' do
          create(:location, :canonical => false, :resource => resource)
          resource.reload
          expect(resource).to_not be_valid
        end
        it 'must be canonical' do
          create(:location, :canonical => true, :resource => resource)
          resource.reload
          expect(resource).to be_valid
        end
      end

      context 'more than one location' do
        it 'must have one canonical location' do
          create(:location, :canonical => false, :resource => resource)
          create(:location, :canonical => true, :resource => resource)
          resource.reload
          expect(resource).to be_valid
        end

        it 'must not have no canonical locations' do
          create(:location, :canonical => false, :resource => resource)
          create(:location, :canonical => false, :resource => resource)
          resource.reload
          expect(resource).to_not be_valid
        end

        it 'must not have two canonical locations' do
          create(:location, :canonical => false, :resource => resource)
          create(:location, :canonical => false, :resource => resource)
          create(:location, :canonical => true, :resource => resource)
          create(:location, :canonical => true, :resource => resource)
          resource.reload
          expect(resource).to_not be_valid
        end
      end
    end

    describe '#to_s' do
      it 'with no legacy locations' do
        location_one = build(:location, :path => '/target', :canonical => true)

        resource = create(:resource,
                          :label => 'Test Resource',
                          :locations => [location_one])

        expect(resource.to_s).to eq(<<-EOS)
  \e[33m(#{resource.id}) Test Resource\e[0m
    [] ----> /target
        EOS
      end

      it 'with 1 legacy location' do
        location_one = build(:location, :path => '/target', :canonical => true)
        location_two = build(:location, :path => '/source1', :canonical => false)

        resource = create(:resource,
                          :label => 'Test Resource',
                          :locations => [location_one, location_two])

        expect(resource.to_s).to eq(<<-EOS)
  \e[33m(#{resource.id}) Test Resource\e[0m
    /source1 ----> /target
        EOS
      end

      it 'with 2 legacy locations' do
        location_one = build(:location, :path => '/target', :canonical => true)
        location_two = build(:location, :path => '/source1', :canonical => false)
        location_three = build(:location, :path => '/source2', :canonical => false)

        resource = create(:resource,
                          :label => 'Test Resource',
                          :locations => [location_one, location_two, location_three])

        expect(resource.to_s).to eq(<<-EOS)
  \e[33m(#{resource.id}) Test Resource\e[0m
    /source1, /source2 ----> /target
        EOS
      end
    end
  end
end
