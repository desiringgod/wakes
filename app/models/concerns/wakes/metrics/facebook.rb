# frozen_string_literal: true
module Wakes
  module Metrics
    module Facebook
      extend ActiveSupport::Concern

      included do
        store_accessor :document, :facebook_count
      end
    end
  end
end
