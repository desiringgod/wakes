# frozen_string_literal: true
module Wakeable
  module HasMany
    extend ActiveSupport::Concern

    included do
      has_many :wakes_resources,
               :class_name => 'Wakes::Resource',
               :inverse_of => :wakeable,
               :as => :wakeable,
               :dependent => :destroy
      accepts_nested_attributes_for :wakes_resources
      attr_accessor :has_many_label, :has_many_path
    end

    def raw_aggregate_pageview_count
      wakes_resources.reload
      wakes_resources.sum("COALESCE((wakes_resources.document ->> 'pageview_count')::int, 0)")
    end

    def raw_aggregate_facebook_count
      wakes_resources.reload
      wakes_resources.sum("COALESCE((wakes_resources.document ->> 'facebook_count')::int, 0)")
    end

    def initialize_wakes_graph
      wakes_value_for(:has_many).each do |options|
        self.has_many_label = options[:label]
        self.has_many_path = options[:path_fragment]

        create_has_many_wake(options)
      end
    end

    def update_wakes_graph
      return initialize_wakes_graph unless wakes_resources.present?
      wakes_value_for(:has_many).each do |options|
        self.has_many_label = options[:label]
        self.has_many_path = options[:path_fragment]

        update_has_many_wake(options) || create_has_many_wake(options)
      end

      update_dependents
    end

    private

    def create_has_many_wake(options)
      wakes_resource = wakes_resources.build(:label => wakes_value_for(:label),
                                             :identifier => options[:identifier])
      wakes_resource.locations.build(:path => wakes_value_for(:path), :canonical => true)
      wakes_resource.save!
    end

    def update_has_many_wake(options)
      if wakes_resource = wakes_resources.find_by(:identifier => options[:identifier])
        update_wakes_resource_label(wakes_resource)
        update_wakes_resource_canonical_location(wakes_resource)
        wakes_resource
      end
    end
  end
end
