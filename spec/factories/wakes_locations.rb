# frozen_string_literal: true

FactoryBot.define do
  factory :location, :class => 'Wakes::Location' do
    sequence(:path) { |n| "/some/path/#{n}" }
    canonical { true }
    resource

    trait :canonical do
      canonical { true }
    end

    trait :non_canonical do
      canonical { false }
    end
  end
end
