class Wakes::Resource < ActiveRecord::Base
  has_many :locations, :foreign_key => :wakes_resource_id
end
