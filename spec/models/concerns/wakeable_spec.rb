require 'rails_helper'

class WakeableModel < ActiveRecord::Base
  include Wakeable
  wakes do
    label :title
    path { "/#{title.parameterize}" }
  end
end

describe Wakeable do
  describe 'configuration' do
    it 'accepts a block that is evaluated in the context of the instance' do
      model_class = Class.new(ActiveRecord::Base) do
        self.table_name = "wakeable_models"
        def self.name ; "WakeableModel" ; end

        include Wakeable
        wakes do
          some_wakes_config_option { my_method }
        end

        def my_method
          'my result'
        end
      end

      instance = model_class.new

      expect(instance.wakes_value_for(:some_wakes_config_option)).to eq('my result')
    end

    it 'accepts a method name that is sent to the instance' do
      model_class = Class.new(ActiveRecord::Base) do
        self.table_name = "wakeable_models"
        def self.name ; "WakeableModel" ; end

        include Wakeable
        wakes do
          some_wakes_config_option :my_method
        end

        def my_method
          'my result'
        end
      end

      instance = model_class.new

      expect(instance.wakes_value_for(:some_wakes_config_option)).to eq('my result')
    end
  end

  context 'on create' do
    it 'sets up a new Wakes::Resource and Wakes::Location' do
      wakeable = WakeableModel.create(:title => 'A Wakeable Model')

      wakes_resource = wakeable.wakes_resources.first
      expect(wakes_resource).to be_a(Wakes::Resource)
      expect(wakes_resource.label).to eq(wakeable.title)

      wakes_location = wakes_resource.canonical_location
      expect(wakes_location).to be_a(Wakes::Location)
      expect(wakes_location.path).to eq('/a-wakeable-model')
    end
  end

  context 'on update' do
    it 'creates a new canonical location on path change' do
      wakeable = WakeableModel.create(:title => 'Some Title')

      wakeable.update!(:title => 'Some New Title')

      wakes_resource = wakeable.wakes_resources.first
      expect(wakes_resource.locations.count).to eq(2)
      expect(wakes_resource.canonical_location.path).to eq('/some-new-title')
      expect(wakes_resource.legacy_locations.first.path).to eq('/some-title')
    end

    it 'changes the Wakes::Resource label on title change' do
      wakeable = WakeableModel.create(:title => 'Some Title')

      wakeable.update!(:title => 'Some New Title')

      wakes_resource = wakeable.wakes_resources.first
      expect(wakes_resource.label).to eq('Some New Title')
    end
  end
end
