# frozen_string_literal: true
FactoryGirl.define do
  factory :location, :class => 'Wakes::Location' do
    sequence(:path) { |n| "/some/path/#{n}" }
    canonical true
    resource
  end
end
