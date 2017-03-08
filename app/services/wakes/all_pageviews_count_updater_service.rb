# frozen_string_literal: true
class Wakes::AllPageviewsCountUpdaterService
  def initialize(start_year, end_year = current_year)
    @start_year = start_year
    @end_year = end_year
  end

  def update_path_counts
    date_ranges.each do |date_range|
      Wakes::GetPathCountsForDateRangeService.new(date_range).path_counts.each do |path, count|
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
end
