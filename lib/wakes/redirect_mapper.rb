# frozen_string_literal: true

require_relative 'uri_from_location_string'

module Wakes
  class RedirectMapper
    attr_accessor :source_host, :source_path, :target_host, :target_path, :label

    def initialize(source_path_or_url, target_path_or_url, label = nil)
      @source_host, @source_path = URIFromLocationString.get_host_and_path(source_path_or_url)
      @target_host, @target_path = URIFromLocationString.get_host_and_path(target_path_or_url)
      @label = label

      puts Wakes.color(:white, "Redirecting from #{source_host}#{source_path} to #{target_host}#{target_path}",
                       :bold => true)
      print_graph('Starting graph')
      both_present || target_present || source_present || none_present
      print_graph('Ending graph')
      puts ''
    end

    private

    def print_graph(notice)
      puts Wakes.color(:magenta, notice)
      Wakes::Resource.where(:id => resources_affected).each { |resource| puts resource.to_s }
    end

    def resources_affected
      @resources_affected ||= []
      @resources_affected << source_location.wakes_resource_id if source_location.present?
      @resources_affected << target_location.wakes_resource_id if target_location.present?
      @resources_affected
    end

    def target_location
      @target_location ||= Wakes::Location.find_by(:host => target_host, :path => target_path)
    end

    def source_location
      @source_location ||= Wakes::Location.find_by(:host => source_host, :path => source_path)
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

      if source_location.canonical?
        target_location.update_attribute(:canonical, true)
        source_location.update_attribute(:canonical, false)
      elsif target_location.canonical?
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
      resource.legacy_locations.create!(:host => source_host, :path => source_path)
    end

    def source_present
      return unless target_location.nil? && source_location.present?

      if source_location.canonical?
        add_target_to_canonical_source
      else
        resource = Wakes.create!(:host => target_host, :path => target_path, :label => label)
        source_location.update_attributes(:canonical => false, :resource => resource)
      end
    end

    def add_target_to_canonical_source
      source_location.resource.locations.update_all(:canonical => false)
      source_location.resource.create_canonical_location!(:host => target_host, :path => target_path)
    end

    def none_present
      return unless target_location.nil? && source_location.nil?

      resource = Wakes.create!(:label => label, :host => target_host, :path => target_path)
      resource.legacy_locations.create!(:host => source_host, :path => source_path)
    end
  end
end
