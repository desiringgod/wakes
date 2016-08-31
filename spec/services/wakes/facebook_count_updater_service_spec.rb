# frozen_string_literal: true
require 'rails_helper'

RSpec.describe Wakes::FacebookCountUpdaterService do
  context 'single location' do
    let!(:location) { create(:location, :facebook_count => 15, :canonical => true) }
    let!(:another_location) { create(:location, :facebook_count => 5, :canonical => false) }
    let!(:resource) { create(:resource, :locations => [location, another_location]) }
    subject { described_class.new(location) }

    describe '#update_facebook_count' do
      before do
        facebook_wrapper = instance_double(Wakes::FacebookMetricsWrapper)
        expect(Wakes::FacebookMetricsWrapper)
          .to receive(:new).with([location.url]).and_return(facebook_wrapper)
        allow(facebook_wrapper).to receive(:share_counts).and_return(location.url => 20)
      end

      context 'with no wakeable' do
        it 'updates the facebook count of the location' do
          subject.update_facebook_count
          expect(location.facebook_count).to eq(20)
        end

        it 'updates the facebook count of the associated resource' do
          subject.update_facebook_count
          expect(resource.facebook_count).to eq(25)
        end
      end

      context 'with wakeable present' do
        let(:wakeable_class) do
          custom_wakeable_class do
            wakes do
              run_if { false }
              has_many do
                [
                  {
                    :label => 'One',
                    :identifier => 'one',
                    :path_fragment => 'one'
                  },
                  {
                    :label => 'Two',
                    :identifier => 'two',
                    :path_fragment => 'two'
                  }
                ]
              end
            end
          end
        end

        let!(:another_resource) { create(:resource, :facebook_count => 20) }
        let!(:wakeable) { wakeable_class.create(:wakes_resources => [resource, another_resource]) }

        it 'updates the facebook count of the associated wakeable' do
          subject.update_facebook_count
          wakeable.reload
          expect(wakeable.facebook_count).to eq(45)
        end
      end
    end
  end

  context 'multiple locations' do
    let!(:location_1) { create(:location, :facebook_count => 4) }
    let!(:location_2) { create(:location, :facebook_count => 10) }
    let!(:location_3) { create(:location, :facebook_count => 12) }

    subject { described_class.new([location_1, location_2, location_3]) }

    describe '#update_facebook_count' do
      before do
        facebook_wrapper = instance_double(Wakes::FacebookMetricsWrapper)
        expect(Wakes::FacebookMetricsWrapper)
          .to receive(:new).and_return(facebook_wrapper)
        allow(facebook_wrapper).to receive(:share_counts).and_return(location_1.url => 20,
                                                                     location_2.url => 30,
                                                                     location_3.url => 40)
      end

      before do
        location_1.resource.locations << create(:location, :non_canonical, :facebook_count => 3)
        location_2.resource.locations << create(:location, :non_canonical, :facebook_count => 6)
      end

      it 'updates the facebook count of all the locations' do
        subject.update_facebook_count
        expect(location_1.facebook_count).to eq(20)
        expect(location_2.facebook_count).to eq(30)
        expect(location_3.facebook_count).to eq(40)
      end

      it 'updates the facebook_count_updated_at for all locations' do
        time = Time.zone.now
        Timecop.freeze(time)
        subject.update_facebook_count
        expect(location_1.facebook_count_updated_at).to be_within(0.1).of(time)
        expect(location_2.facebook_count_updated_at).to be_within(0.1).of(time)
        expect(location_3.facebook_count_updated_at).to be_within(0.1).of(time)
      end

      it 'aggregates the facebook counts of associated resource' do
        subject.update_facebook_count
        expect(location_1.resource.facebook_count).to eq(23)
        expect(location_2.resource.facebook_count).to eq(36)
      end
    end
  end
end
