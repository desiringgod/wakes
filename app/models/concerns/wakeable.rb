module Wakeable
  extend ActiveSupport::Concern

  included do
    has_many :wakes_resources, :class_name => 'Wakes::Resource', :inverse_of => :wakeable, :as => :wakeable
    accepts_nested_attributes_for :wakes_resources

    after_create do
      wakes_resource = wakes_resources.build(:label => wakes_label)
      wakes_resource.locations.build(:path => wakes_path, :canonical => true)
      wakes_resource.save!
    end

    after_update do
      wakes_resource = wakes_resources.first

      if changes.include?('title')
        wakes_resource.update(:label => title)
      end

      if wakes_resource.canonical_location.path != wakes_path
        wakes_resource.locations.update_all(:canonical => false)
        wakes_resource.locations.create(:path => wakes_path, :canonical => true)
      end

      if respond_to?(:wakes_dependents)
        wakes_dependents.map(&:save)
      end
    end
  end

  module ClassMethods
    def wakes(&block)
      Configuration.new(self, &block)
    end
  end

  class Configuration
    def initialize(wakeable_klass, &block)
      @wakeable_klass = wakeable_klass

      instance_exec(&block)
    end

    def label(&block)
      @wakeable_klass.send(:define_method, :wakes_label, &block)
    end

    def path(&block)
      @wakeable_klass.send(:define_method, :wakes_path, &block)
    end

    def dependents(&block)
      @wakeable_klass.send(:define_method, :wakes_dependents, &block)
    end
  end
end
