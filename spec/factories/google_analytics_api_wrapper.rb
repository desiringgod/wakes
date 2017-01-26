# frozen_string_literal: true
FactoryGirl.define do
  factory :page_views, :class => 'Wakes::GoogleAnalyticsApiWrapper::PageViews' do
    sequence(:url) { |n| "/path/#{n}" }
    count 100

    initialize_with do
      new(Wakes::GoogleAnalyticsApiWrapper::Url.new(url), count)
    end
  end
end
