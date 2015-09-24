require 'rails_helper'

RSpec.describe Wakes::Resource, type: :model do
  it 'has a label' do
    expect(build(:resource, :label => 'Some Label').label).to eq('Some Label')
  end

  it 'has many locations' do
    location_one = create(:location)
    location_two = create(:location)

    resource = create(:resource, :locations => [location_one, location_two])

    expect(resource.locations).to contain_exactly(location_one, location_two)
  end
end
