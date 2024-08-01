# frozen_string_literal: true

require 'googleauth'
require 'google/apis/analyticsdata_v1beta'

class Wakes::GoogleAnalyticsApiWrapper
  AUTHORIZATION_SCOPE = 'https://www.googleapis.com/auth/analytics.readonly'
  PAGE_SIZE = 1_000

  def get_page_of_pageviews(page, start_date:, end_date:, property_id: Wakes.configuration.ga_profiles['default'])
    results = get_page(page, start_date, end_date, property_id)
    rows = results.rows || []

    create_page(rows, results.row_count <= PAGE_SIZE * page)
  end

  private

  def get_page(page, start_date, end_date, property_id)
    request = Google::Apis::AnalyticsdataV1beta::RunReportRequest.new(
      dimensions: [Google::Apis::AnalyticsdataV1beta::Dimension.new(name: 'pagePath')],
      metrics: [Google::Apis::AnalyticsdataV1beta::Metric.new(name: 'screenPageViews')],
      date_ranges: [Google::Apis::AnalyticsdataV1beta::DateRange.new(start_date: format_date(start_date), end_date: format_date(end_date))],
      order_bys: [Google::Apis::AnalyticsdataV1beta::OrderBy.new(
        metric: Google::Apis::AnalyticsdataV1beta::MetricOrderBy.new(metric_name: 'screenPageViews'),
        desc: true
      )],
      offset: start_index_for_page(page),
      limit: PAGE_SIZE
    )

    authorized_analytics_service.run_property_report("properties/#{property_id}", request)
  end

  def format_date(date)
    date.to_date.to_s
  end

  def create_page(rows, end_of_page)
    Page.new(page_views_from_rows(rows), end_of_page)
  end

  def page_views_from_rows(rows)
    rows.map { |row| create_page_views(row) }.compact
  end

  def create_page_views(row)
    PageViews.new(Url.new(row.dimension_values[0].value), row.metric_values[0].value.to_i)
  rescue URI::InvalidURIError
    # Ignore invalid URIs, we won't being doing lookups
    puts "Invalid path, not attempting to lookup: #{row.dimension_values[0].value}".red
  end

  # indexes start at 0, so page 1 would = 0, page 2 would = 1000, page 3 would = 2000, etc.
  def start_index_for_page(page)
    PAGE_SIZE * (page - 1)
  end

  def authorized_analytics_service
    @service ||= Google::Apis::AnalyticsdataV1beta::AnalyticsDataService.new.tap do |analytics|
      analytics.authorization = credentials
    end
  end

  def credentials
    @credentials ||= Google::Auth::ServiceAccountCredentials.from_env(AUTHORIZATION_SCOPE)
  end

  Page = Struct.new(:rows, :end?)

  class PageViews
    attr_reader :count, :url

    def initialize(url, count)
      @url = url
      @count = count
    end

    def to_s
      "#{url}: #{count}"
    end
  end

  class Url
    attr_reader :uri
    delegate :query, :path, :to => :uri

    def initialize(uri)
      @uri = URI.parse(uri)
    end

    def to_s
      uri.to_s
    end

    def params
      @params ||= CGI.parse(query || '')
    end

    def lang
      return @lang if defined?(@lang)
      @lang = params.include?('lang') ? params['lang'][0] : nil
    end

    def extension
      return @extension if defined?(@extension)
      @extension = File.extname(path).delete('.').presence
    end

    def sanitized_path
      @sanitized_path ||= path_without_extension + extension_if_not_html + lang_if_not_en
    end

    private

    def path_without_extension
      path.rpartition('.').first.presence || path
    end

    def extension_if_not_html
      extension.present? && extension != 'html' ? ".#{extension}" : ''
    end

    def lang_if_not_en
      lang.present? && lang != 'en' ? "?lang=#{lang}" : ''
    end
  end
end
