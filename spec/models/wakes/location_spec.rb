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
  end

  it 'belongs to a resource' do
    resource = create(:resource)

    location = create(:location, :resource => resource)

    expect(location.resource).to eq(resource)
  end
end
