# frozen_string_literal: true
class Wakes::Resource < ActiveRecord::Base
  with_options :class_name => 'Wakes::Location', :foreign_key => :wakes_resource_id, :inverse_of => :resource do
    has_many :locations
    has_one :canonical_location, -> { canonical }
    has_many :legacy_locations, -> { legacy }
  end

  accepts_nested_attributes_for :locations

  belongs_to :wakeable, :polymorphic => true

  with_options :if => ->(resource) { resource.locations.count > 0 } do
    validate :one_location_is_canonical
    validate :only_one_location_is_canonical
  end

  store_accessor :document, :pageview_count

  private

  def one_location_is_canonical
    if locations.where(:canonical => true).count < 1
      errors.add(:locations, 'one must be canonical')
    end
  end

  def only_one_location_is_canonical
    if locations.where(:canonical => true).count > 1
      errors.add(:locations, 'only one may be canonical')
    end
  end
end
