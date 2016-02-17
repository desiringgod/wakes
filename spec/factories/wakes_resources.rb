# frozen_string_literal: true
FactoryGirl.define do
  factory :resource, :class => 'Wakes::Resource' do
    sequence(:label) { |n| "Wakes Resource #{n}" }
  end
end
