# frozen_string_literal: true
module Wakes
  class RedirectMapper
    attr_accessor :source, :target, :label

    def self.redirect(source, target, label = nil)
      new(source, target, label)
    end

    def initialize(source, target, label = nil)
      @source = source
      @target = target
      @label = label
      puts "Redirecting from #{source} to #{target}"

      both_present || target_present || source_present || none_present
    end

    def target_location
      @target_location ||= Wakes::Location.find_by(:path => target)
    end

    def source_location
      @source_location ||= Wakes::Location.find_by(:path => source)
    end

    def create_new
      resource = Wakes::Resource.create!(:label => label)
      target_location.update_attributes(:canonical => true, :resource => resource)
      source_location.update_attributes(:canonical => false, :resource => resource)
    end

    def both_present
      return unless target_location.present? && source_location.present?

      same_resource || different_resource
    end

    def same_resource
      return unless target_location.resource == source_location.resource

      case
      when source_location.canonical?
        target_location.update_attribute(:canonical, true)
        source_location.update_attribute(:canonical, false)
      when target_location.canonical?
      else
        create_new
      end
    end

    def different_resource
      return if target_location.resource == source_location.resource

      merge_two_canonical_locations ||
        point_source_location_to_target_resource ||
        point_target_location_to_source_resource ||
        create_new
    end

    def merge_two_canonical_locations
      return unless target_location.canonical? && source_location.canonical?
      resource = target_location.resource
      old_resource = source_location.resource
      old_resource.locations.each do |location|
        location.update_attributes(:canonical => false, :resource => resource)
      end
      old_resource.reload
      old_resource.destroy
    end

    def point_source_location_to_target_resource
      return unless target_location.canonical? && !source_location.canonical?

      source_location.update_attributes(:resource => target_location.resource)
    end

    def point_target_location_to_source_resource
      return unless !target_location.canonical? && source_location.canonical?

      source_location.update_attribute(:canonical, false)
      target_location.update_attributes(:canonical => true, :resource => source_location.resource)
    end

    def target_present
      return unless target_location.present? && source_location.nil?

      resource = target_location.resource
      resource.legacy_locations.create!(:path => source)
    end

    def source_present
      return unless target_location.nil? && source_location.present?

      if source_location.canonical?
        add_target_to_canonical_source
      else
        resource = Wakes.create!(:path => target, :label => label)
        source_location.update_attributes(:canonical => false, :resource => resource)
      end
    end

    def add_target_to_canonical_source
      source_location.resource.locations.update_all(:canonical => false)
      source_location.resource.create_canonical_location!(:path => target)
    end

    def none_present
      return unless target_location.nil? && source_location.nil?

      resource = Wakes.create!(:label => label, :path => target)
      resource.legacy_locations.create!(:path => source)
    end
  end
end
