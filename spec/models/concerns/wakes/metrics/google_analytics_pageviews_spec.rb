# frozen_string_literal: true
require 'rails_helper'

RSpec.describe Wakes::Metrics::GoogleAnalyticsPageviews do
  describe '#pageview_count' do
    it 'sums all the pageview_counts' do
      location = create(:location, :pageview_counts => { 2010 => 100, 2011 => 501, 2012 => 201 })
      puts location.inspect
      expect(location.pageview_count).to eq(802)
    end
  end

  describe '#pageview_counts' do
    it 'has a default value of {}' do
      location = build(:location)
      expect(location.pageview_counts).to eq({})
    end
  end
end
