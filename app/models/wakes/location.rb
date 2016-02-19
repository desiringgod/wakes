# frozen_string_literal: true
class Wakes::Location < ActiveRecord::Base
  include Wakes::Metrics::GoogleAnalyticsPageviews
  include Wakes::Metrics::Facebook

  validates :path, :format => { :with => %r{\A\/} }, :uniqueness => true
  belongs_to :resource, :foreign_key => :wakes_resource_id, :inverse_of => :locations

  scope :canonical, -> { where(:canonical => true) }
  scope :legacy, -> { where(:canonical => false) }

  def self.find_by_url(url)
    uri = URI(url)
    fail HostMismatchError, 'host does not match' if !ENV['DEFAULT_HOST'].nil? && ENV['DEFAULT_HOST'] != uri.host
    find_by!(:path => URI(url).path)
  end

  def label
    path
  end

  def url(protocol: 'http', host: ENV['DEFAULT_HOST'])
    "#{protocol}://#{host}#{path}"
  end

  class HostMismatchError < StandardError; end
end
