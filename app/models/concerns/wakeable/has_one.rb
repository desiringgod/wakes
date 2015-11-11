module Wakeable
  module HasOne
    extend ActiveSupport::Concern

    included do
      has_one :wakes_resource, :class_name => 'Wakes::Resource', :inverse_of => :wakeable, :as => :wakeable
      accepts_nested_attributes_for :wakes_resource
    end

    def initialize_wakes_graph
      wakes_resource = build_wakes_resource(:label => wakes_value_for(:label))
      wakes_resource.locations.build(:path => wakes_value_for(:path), :canonical => true)
      wakes_resource.save!
    end

    def update_wakes_graph
      update_wakes_resource_label(wakes_resource)
      update_wakes_resource_canonical_location(wakes_resource)
      update_dependents
    end
  end
end
