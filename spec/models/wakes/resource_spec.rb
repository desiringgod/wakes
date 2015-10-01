require 'rails_helper'

RSpec.describe Wakes::Resource, type: :model do
  it 'has a label' do
    expect(build(:resource, :label => 'Some Label').label).to eq('Some Label')
  end

  describe 'locations' do
    it 'has many locations' do
      location_one = create(:location)
      location_two = create(:location)

      resource = create(:resource, :locations => [location_one, location_two])

      expect(resource.locations).to contain_exactly(location_one, location_two)
    end

    it 'has one canonical location' do
      location_one = create(:location, :canonical => true)
      location_two = create(:location, :canonical => false)

      resource = create(:resource, :locations => [location_one, location_two])

      expect(resource.canonical_location).to eq(location_one)
    end

    it 'has many legacy locations' do
      location_one = create(:location, :canonical => true)
      location_two = create(:location, :canonical => false)
      location_three = create(:location, :canonical => false)

      resource = create(:resource, :locations => [location_one, location_two, location_three])

      expect(resource.legacy_locations).to contain_exactly(location_two, location_three)
    end

    describe 'canonical locations' do
      it 'if there is one location, it must be canonical' do
        bad_resource = create(:resource, :locations => [create(:location, :canonical => false)])
        expect(bad_resource).to_not be_valid

        good_resource = create(:resource, :locations => [create(:location, :canonical => true)])
        expect(good_resource).to be_valid
      end

      it 'if there is more than one location, one and only one must be canonical' do
        location_one = create(:location, :canonical => false)
        location_two = create(:location, :canonical => false)
        canonical_location_one = create(:location, :canonical => true)
        canonical_location_two = create(:location, :canonical => true)

        bad_resource = create(:resource, :locations => [location_one, location_two])
        expect(bad_resource).to_not be_valid

        bad_resource = create(:resource, :locations => [location_one, location_two, canonical_location_one, canonical_location_two])
        expect(bad_resource).to_not be_valid

        good_resource = create(:resource, :locations => [location_one, location_two, canonical_location_one])
        expect(good_resource).to be_valid
      end
    end
  end
end
