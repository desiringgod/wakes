# frozen_string_literal: true
module Wakes
  module Redirectors
    extend ActiveSupport::Concern

    included do
      store_accessor :document, :legacy_paths_in_redis
      after_touch :rebuild_redirect_graph

      def rebuild_redirect_graph
        destroy_redirect_graph
        create_redirect_graph
      end

      def create_redirect_graph
        reload
        return unless canonical_location.present?
        legacy_locations.reload
        legacy_paths_in_redis = legacy_locations.map do |legacy_location|
          Wakes::REDIS.set(legacy_location.path, canonical_location.path)
          legacy_location.path
        end
        update_attribute(:legacy_paths_in_redis, legacy_paths_in_redis)
      end

      def destroy_redirect_graph
        reload
        if legacy_paths_in_redis.present?
          Wakes::REDIS.del(legacy_paths_in_redis)
          update_attribute(:legacy_paths_in_redis, nil)
        end
      end
    end
  end
end
