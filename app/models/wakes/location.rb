# frozen_string_literal: true
class Wakes::Location < ActiveRecord::Base
  include Wakes::Metrics::GoogleAnalyticsPageviews

  validates :path, :format => { :with => %r{\A\/} }, :uniqueness => true
  belongs_to :resource, :foreign_key => :wakes_resource_id, :inverse_of => :locations, :touch => true

  scope :canonical, -> { where(:canonical => true) }
  scope :legacy, -> { where(:canonical => false) }

  def label
    path
  end
end
