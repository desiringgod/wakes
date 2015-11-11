class Wakes::Location < ActiveRecord::Base
  validates :path, :format => { :with => %r{\A\/} }, :uniqueness => true
  belongs_to :resource, :foreign_key => :wakes_resource_id, :inverse_of => :locations

  scope :canonical, -> { where(:canonical => true) }
  scope :legacy, -> { where(:canonical => false) }

  def label
    path
  end
end
