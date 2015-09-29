class Wakes::Location < ActiveRecord::Base
  validates :path, :format => { :with => /\A\// }, :uniqueness => true
  belongs_to :resource, :foreign_key => :wakes_resource_id
end
