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
      it 'returns an unpersisted Wakes::Resource' do
        wakes_resource = Wakes.build(:label => 'Some Label', :wakeable => wakeable, :path => '/some/path', :identifier => 'some-identifier')

        expect(wakes_resource).to_not be_persisted
        expect(wakes_resource.label).to eq('Some Label')
        expect(wakes_resource.wakeable).to eq(wakeable)
        expect(wakes_resource.identifier).to eq('some-identifier')
        expect(wakes_resource.locations.first.path).to eq('/some/path')
      end
    end

    describe '::create' do
      context 'with good input' do
        before do
          @wakes_resource_creation = Wakes.create(:label => 'Some Label', :wakeable => wakeable, :path => '/some/path', :identifier => 'some-identifier')
        end

        it 'returns true' do
          expect(@wakes_resource_creation).to eq(true)
        end

        it 'creates the Wakes::Resource' do
          wakes_resource = Wakes::Resource.last

          expect(wakes_resource.label).to eq('Some Label')
          expect(wakes_resource.wakeable).to eq(wakeable)
          expect(wakes_resource.identifier).to eq('some-identifier')
          expect(wakes_resource.locations.first.path).to eq('/some/path')
        end
      end

      context 'with bad input' do
        before do
          @wakes_resource_creation = Wakes.create(:label => 'Some Label', :wakeable => wakeable, :path => 'some/path', :identifier => 'some-identifier')
        end

        it 'returns false' do
          expect(@wakes_resource_creation).to eq(false)
        end

        it 'creates no Wakes::Resource' do
          expect(Wakes::Resource.last).to be_nil
        end
      end
    end

    describe '::create!' do
      context 'with good input' do
        before do
          @wakes_resource_creation = Wakes.create!(:label => 'Some Label', :wakeable => wakeable, :path => '/some/path', :identifier => 'some-identifier')
        end

        it 'returns true' do
          expect(@wakes_resource_creation).to eq(true)
        end

        it 'creates the Wakes::Resource' do
          wakes_resource = Wakes::Resource.last

          expect(wakes_resource.label).to eq('Some Label')
          expect(wakes_resource.wakeable).to eq(wakeable)
          expect(wakes_resource.identifier).to eq('some-identifier')
          expect(wakes_resource.locations.first.path).to eq('/some/path')
        end
      end

      context 'with bad input' do
        it 'raises an error and creates no Wakes::Resource' do
          expect do
            Wakes.create!(:label => 'Some Label', :wakeable => wakeable, :path => 'some/path', :identifier => 'some-identifier')
          end.to raise_error(ActiveRecord::RecordInvalid)

          expect(Wakes::Resource.last).to be_nil
        end
      end
    end
  end
end
