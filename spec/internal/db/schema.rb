ActiveRecord::Schema.define do
  create_table 'wakeable_models' do |t|
    t.string 'title'
    t.integer 'parent_id'
  end
end
