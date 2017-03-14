# frozen_string_literal: true
require 'googleauth'
require 'google/apis/analytics_v3'

class Wakes::GoogleAnalyticsApiWrapper
  AUTHORIZATION_SCOPE = 'https://www.googleapis.com/auth/analytics.readonly'
  PAGE_SIZE = 1_000

  def get_page_of_pageviews(page, start_date:, end_date:, profile_id: Wakes.configuration.ga_profiles['default'])
    results = get_page(page, start_date, end_date, profile_id)
    rows = results.rows || []
    create_page(rows, rows.count < results.items_per_page)
  end

  private

  def get_page(page, start_date, end_date, profile_id)
    authorized_analytics_service.get_ga_data(
      "ga:#{profile_id}",
      format_date(start_date),
      format_date(end_date),
      'ga:pageviews',
      :dimensions => 'ga:pagePath',
      :sort => '-ga:pageviews',
      :start_index => start_index_for_page(page)
    )
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
    PageViews.new(Url.new(row[0]), row[1].to_i)
  rescue URI::InvalidURIError
    # Ignore invalid URIs, we won't being doing lookups
    puts "Invalid path, not attempting to lookup: #{row[0]}".red
  end

  # indexes start at 1, so page 1 would = 1, page 2 would = 1001, page 3 would = 2001, etc.
  def start_index_for_page(page)
    (PAGE_SIZE * page) - (PAGE_SIZE - 1)
  end

  def authorized_analytics_service
    @service ||= Google::Apis::AnalyticsV3::AnalyticsService.new.tap do |analytics|
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
