require 'rails_helper'

class WakeableModel < ActiveRecord::Base
  include Wakeable
  belongs_to :parent, :class_name => 'WakeableModel'
  has_many :children, :class_name => 'WakeableModel', :foreign_key => :parent_id

  wakes do
    label :title
    dependents :children
    path do
      if parent.present?
        "/#{parent.title.parameterize}/#{title.parameterize}"
      else
        "/#{title.parameterize}"
      end
    end
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

    it 'fails gracefully if value is not defined' do
      model_class = Class.new(ActiveRecord::Base) do
        self.table_name = "wakeable_models"
        def self.name ; "WakeableModel" ; end

        include Wakeable
        wakes do
        end
      end

      instance = model_class.new

      expect(instance.wakes_value_for(:some_wakes_config_option)).to be_nil
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

    it 'creates new canonical locations on parent title change' do
      parent_wakeable = WakeableModel.create(:title => 'Some Title')
      child_wakeable_one = WakeableModel.create(:title => 'One', :parent => parent_wakeable)
      child_wakeable_two = WakeableModel.create(:title => 'Two', :parent => parent_wakeable)

      parent_wakeable.update!(:title => 'Some New Title')

      wakes_resource = parent_wakeable.wakes_resources.first
      expect(wakes_resource.locations.count).to eq(2)
      expect(wakes_resource.canonical_location.path).to eq('/some-new-title')
      expect(wakes_resource.legacy_locations.first.path).to eq('/some-title')

      wakes_resource = child_wakeable_one.wakes_resources.first
      expect(wakes_resource.locations.count).to eq(2)
      expect(wakes_resource.canonical_location.path).to eq('/some-new-title/one')
      expect(wakes_resource.legacy_locations.first.path).to eq('/some-title/one')

      wakes_resource = child_wakeable_two.wakes_resources.first
      expect(wakes_resource.locations.count).to eq(2)
      expect(wakes_resource.canonical_location.path).to eq('/some-new-title/two')
      expect(wakes_resource.legacy_locations.first.path).to eq('/some-title/two')
    end
  end
end
