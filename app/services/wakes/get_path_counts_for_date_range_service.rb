# frozen_string_literal: true

module Wakes
  class GetPathCountsForDateRangeService
    BLOCK_AFTER_ERROR_TIME = 10.minutes

    attr_reader :start_date, :end_date

    def initialize(date_range, logger: Rails.logger)
      @start_date = date_range.first
      @end_date = date_range.last
      @logger = LoggerWrapper.new(logger)
    end

    def path_counts
      @path_counts ||= load_path_counts
    end

    private

    attr_reader :logger

    def load_path_counts
      loaded_path_counts = Hash.new(0)

      loop do
        page = load_next_page
        process_page(page, loaded_path_counts)
        break if page.end?
      end

      loaded_path_counts
    end

    def load_next_page
      @page_number ||= 0
      @page_number += 1
      attempt = 0

      begin
        attempt += 1
        logger.info "Attempt number #{attempt}: Querying GA for page #{@page_number} for #{start_date} - #{end_date}"
        google_analytics.get_page_of_pageviews(@page_number, :start_date => start_date, :end_date => end_date)
      rescue Google::Apis::Error => err
        block_for_page(@page_number, err)
        if attempt < 4
          retry
        else
          raise err
        end
      end
    end

    def block_for_page(page_number, error)
      logger.warn "Error using Google Analytics API: #{error.status_code} #{error.message}"
      logger.warn "Sleeping for #{BLOCK_AFTER_ERROR_TIME.inspect}, then retrying page request: #{page_number}"
      sleep BLOCK_AFTER_ERROR_TIME.to_i
    end

    def process_page(page, counts)
      page.rows.each do |pageviews|
        counts[pageviews.url.sanitized_path] += pageviews.count
      end
    end

    def google_analytics
      @google_analytics ||= Wakes::GoogleAnalyticsApiWrapper.new
    end

    class LoggerWrapper
      def initialize(logger)
        @logger = logger
      end

      %w[warn error info debug fatal].each do |message_type|
        define_method(message_type) do |message|
          @logger.send(message_type, prepare_message(message))
        end
      end

      private

      def prepare_message(message)
        "#{service}: #{message}"
      end

      def service
        @service ||= self.class.to_s.split('::')[-2].underscore
      end
    end
  end
end
