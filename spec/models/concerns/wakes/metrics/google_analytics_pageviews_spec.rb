# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Wakes::Metrics::GoogleAnalyticsPageviews do
  describe '#pageview_count' do
    before { Timecop.freeze(2015, 10, 1, 12, 0, 0) }

    it 'sums all the pageview_counts and todays pageview count' do
      location = create(
        :location,
        :pageview_counts => { 2010 => 100, 2011 => 501, 2012 => 201 },
        :todays_pageview_counts => { '2015-10-01' => 20, '2015-09-30' => 30 }
      )
      expect(location.pageview_count).to eq(822)
    end
  end

  describe '#pageview_counts' do
    it 'has a default value of {}' do
      location = build(:location)
      expect(location.pageview_counts).to eq({})
    end
  end
end
