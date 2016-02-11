# frozen_string_literal: true
module Wakes
  module Metrics
    module Facebook
      extend ActiveSupport::Concern

      included do
        store_accessor :document, :facebook_count, :facebook_count_updated_at

        def self.ordered_for_facebook_updates
          order("document->'facebook_count_updated_at' ASC NULLS FIRST")
        end
      end
    end
  end
end
