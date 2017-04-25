# frozen_string_literal: true

FactoryGirl.define do
  factory :resource, :class => 'Wakes::Resource' do
    sequence(:label) { |n| "Wakes Resource #{n}" }

    trait :with_locations do
      after(:build) do |resource|
        resource.locations << build(:location, :canonical)
        rand(3).times { resource.locations << build(:location, :non_canonical) }
      end
    end
  end
end
