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
      end
    end

    describe '::create' do
      context 'with good input' do
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
      context 'with good input' do
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
end
