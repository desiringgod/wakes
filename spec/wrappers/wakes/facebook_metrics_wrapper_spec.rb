# frozen_string_literal: true
require 'rails_helper'

RSpec.describe Wakes::FacebookMetricsWrapper do
  subject { Wakes::FacebookMetricsWrapper.new('http://www.example.com') }

  describe '#metrics', :vcr do
    it 'returns a Hash' do
      expect(subject.metrics).to be_a Hash
    end

    it 'includes total_count in the returned Hash' do
      expect(subject.metrics).to include('total_count')
    end

    it 'attemts requests 3 times on hitting an exception' do
      allow(subject).to receive(:make_request).and_raise(StandardError)
      expect(subject).to receive(:make_request).thrice
      expect { subject.metrics }.to raise_error(StandardError)
    end
  end

  describe '#total_count', :vcr do
    it 'returns the total facebook count for the url' do
      expect(subject.total_count).to eq 14_600_717
    end
  end
end
