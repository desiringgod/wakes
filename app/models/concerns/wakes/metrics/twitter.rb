# frozen_string_literal: true

module Wakes
  module Metrics
    module Twitter
      extend ActiveSupport::Concern

      included do
        store_accessor :document, :twitter_count
      end
    end
  end
end
