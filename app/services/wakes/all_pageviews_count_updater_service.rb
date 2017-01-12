# frozen_string_literal: true
require 'google/apis/analytics_v3'

class Wakes::AllPageviewsCountUpdaterService
  def initialize(start_year, end_year = current_year)
    @start_year = start_year
    @end_year = end_year
  end

  def update_path_counts
    date_ranges.each do |date_range|
      GetPathCountsForDateRangeService.new(date_range).path_counts.each do |path, count|
        update_path_count(path, count, date_range)
      end
    end
  end

  private

  attr_reader :start_year, :end_year

  def current_year
    Date.today.year
  end

  def date_ranges
    @date_ranges ||= begin
      start_date = Date.new(start_year, 1, 1)
      end_date = current_year == end_year ? 1.day.ago.to_date : Date.new(end_year, 12, 31)
      DateRanges.new(start_date..end_date, :year)
    end
  end

  def update_path_count(path, count, date_range)
    location = Wakes::Location.where(:path => path).first
    return unless location.present?

    location.pageview_counts[date_range.first.year] = count
    location.save
    location.resource&.update_pageview_count
    begin
      location.resource.wakeable&.update_pageview_count
    rescue NameError => ex # Invalid wakeable
      puts ex.message
    end
  end

  class DateRanges
    include Enumerable

    def initialize(date_range, length)
      @date_range = date_range
      @length = length
    end

    def each
      sorted_ranges.each { |range| yield range }
    end

    private

    def range_groups
      @range_groupings ||= @date_range.group_by(&@length)
    end

    def sorted_ranges
      @sorted_dates ||= range_groups.map do |_, dates|
        dates.sort!
        dates.first..dates.last
      end
    end
  end

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

      begin
        logger.info "Going to request page #{@page_number} for #{start_date} - #{end_date} from Google Analytics"
        google_analytics.get_page_of_pageviews(@page_number, :start_date => start_date, :end_date => end_date)
      rescue Google::Apis::Error => err
        block_for_page(@page_number, err)
        retry
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
  end

  class LoggerWrapper
    def initialize(logger)
      @logger = logger
    end

    %w(warn error info debug fatal).each do |message_type|
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
