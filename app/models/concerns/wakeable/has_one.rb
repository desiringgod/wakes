# frozen_string_literal: true

module Wakeable
  module HasOne
    extend ActiveSupport::Concern

    included do
      has_one :wakes_resource,
              :class_name => 'Wakes::Resource',
              :inverse_of => :wakeable,
              :as => :wakeable,
              :dependent => :destroy
      accepts_nested_attributes_for :wakes_resource
    end

    def raw_aggregate_pageview_count
      wakes_resource.reload
      wakes_resource.pageview_count
    end

    def raw_aggregate_facebook_count
      wakes_resource.reload
      wakes_resource.facebook_count
    end

    def initialize_wakes_graph
      wakes_resource = build_wakes_resource(:label => wakes_value_for(:label))
      wakes_resource.locations.build(:path => wakes_value_for(:path), :canonical => true)
      wakes_resource.save!
    end

    def update_wakes_graph
      return initialize_wakes_graph unless wakes_resource.present?
      update_wakes_resource_label(wakes_resource)
      update_wakes_resource_canonical_location(wakes_resource)
      update_dependents
    end
  end
end
