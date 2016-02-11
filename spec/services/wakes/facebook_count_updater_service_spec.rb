# frozen_string_literal: true
require 'rails_helper'

RSpec.describe Wakes::FacebookCountUpdaterService do
  let!(:location) { create(:location, :facebook_count => 15, :canonical => true) }
  let!(:another_location) { create(:location, :facebook_count => 5) }
  let!(:resource) { create(:resource, :locations => [location, another_location]) }
  subject { described_class.new(location) }

  describe '#update_facebook_count' do
    before do
      facebook_wrapper = instance_double(Wakes::FacebookMetricsWrapper)
      expect(Wakes::FacebookMetricsWrapper)
        .to receive(:new).with(location.url).and_return(facebook_wrapper)
      allow(facebook_wrapper).to receive(:total_count).and_return(20)
    end

    it 'updates the facebook count of the location' do
      subject.update_facebook_count
      expect(location.facebook_count).to eq(20)
    end

    it 'updates the facebook count of the associated resource' do
      subject.update_facebook_count
      expect(resource.facebook_count).to eq(25)
    end
  end
end
