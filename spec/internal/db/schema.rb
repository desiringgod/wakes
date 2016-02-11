# frozen_string_literal: true
ActiveRecord::Schema.define do
  create_table 'wakeable_models' do |t|
    t.string 'title'
    t.integer 'parent_id'
    t.integer 'pageview_count'
    t.integer 'facebook_count'
  end
end
