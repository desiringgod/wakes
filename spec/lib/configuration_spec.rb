# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Wakes do
  describe '::configuration' do
    it 'returns the Configuration class' do
      expect(Wakes.configuration).to be_a Wakes::Configuration
    end
  end

  describe '::configure' do
    it 'takes the block to set up the configuration' do
      Wakes.configure do |config|
        config.enabled = false
      end
      expect(Wakes.configuration.enabled).to be false

      Wakes.configure do |config|
        config.enabled = true
      end
      expect(Wakes.configuration.enabled).to be true
    end
  end
end
