# frozen_string_literal: true
class Wakes::Location < ActiveRecord::Base
  include Wakes::Metrics::GoogleAnalyticsPageviews
  include Wakes::Metrics::Facebook
  include Wakes::Metrics::Twitter

  validates :path, :format => { :with => %r{\A\/} }, :uniqueness => { :scope => :host }
  belongs_to :resource, :foreign_key => :wakes_resource_id, :inverse_of => :locations, :touch => true

  scope :canonical, -> { where(:canonical => true) }
  scope :legacy, -> { where(:canonical => false) }

  def label
    path_or_url.sub(%r{^https?://}, '')
  end

  def url(protocol: 'http', host_override: nil)
    calculated_hostname = host_override || host || ENV['DEFAULT_HOST']
    "#{protocol}://#{calculated_hostname}#{path}"
  end

  def path_or_url
    host.present? ? url : path
  end
end
