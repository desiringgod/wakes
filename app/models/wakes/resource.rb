# frozen_string_literal: true
class Wakes::Resource < ActiveRecord::Base
  include Wakes::Redirectors

  with_options :class_name => 'Wakes::Location', :foreign_key => :wakes_resource_id, :inverse_of => :resource do
    has_many :locations, :dependent => :destroy
    has_one :canonical_location, -> { canonical }
    has_many :legacy_locations, -> { legacy }
  end

  accepts_nested_attributes_for :locations

  belongs_to :wakeable, :polymorphic => true

  with_options :if => ->(resource) { resource.locations.count > 0 } do
    validate :one_location_is_canonical
    validate :only_one_location_is_canonical
  end

  store_accessor :document, :pageview_count, :facebook_count

  validates :label, :presence => true

  def to_s
    <<-EOS
  #{Wakes.color(:yellow, "(#{id}) #{label}")}
    [#{legacy_locations.pluck(:path).join(', ')}] ----> #{canonical_location.path}
    EOS
  end

  def update_facebook_count
    self.facebook_count = locations.sum("COALESCE((wakes_locations.document ->> 'facebook_count')::int, 0)")
    save!
  end

  private

  def one_location_is_canonical
    if locations.where(:canonical => true).count < 1
      errors.add(:locations, 'None of the associated Locations are canonical. At least one must be canonical')
    end
  end

  def only_one_location_is_canonical
    if locations.where(:canonical => true).count > 1
      errors.add(:locations, 'More than one of the associated Locations are canonical. Only one may be canonical')
    end
  end
end
