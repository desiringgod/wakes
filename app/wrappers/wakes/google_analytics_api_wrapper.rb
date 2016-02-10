# frozen_string_literal: true
require 'googleauth'
require 'google/apis/analytics_v3'

class Wakes::GoogleAnalyticsApiWrapper
  AUTHORIZATION_SCOPE = 'https://www.googleapis.com/auth/analytics.readonly'

  # More precisely, this sums up the pageviews for this particular path and
  # any other paths with query strings
  def get_pageviews_for_path(path, start_date:, end_date:)
    authorized_analytics_service.get_ga_data(
      "ga:#{ENV['GOOGLE_ANALYTICS_PROFILE_ID']}",
      format_date(start_date),
      format_date(end_date),
      'ga:pageviews',
      :dimensions => 'ga:pagePath',
      :filters => PrepareFiltersForGAPagePath.new(path).filters,
      :sort => '-ga:pageviews'
    ).totals_for_all_results['ga:pageviews'].to_i
  end

  private

  def authorized_analytics_service
    @service ||= Google::Apis::AnalyticsV3::AnalyticsService.new.tap do |analytics|
      analytics.authorization = credentials
    end
  end

  def credentials
    @credentials ||= Google::Auth::ServiceAccountCredentials.from_env(AUTHORIZATION_SCOPE)
  end

  class PrepareFiltersForGAPagePath
    attr_accessor :path

    def initialize(path)
      @path = path
    end

    def filters
      str = "ga:pagePath=~#{regexp_string_for_path}"
      str += ';ga:pagePath!@lang=' unless lang_included?
      str
    end

    # This is a string written to match exact path and any params, but no subdirectories.
    # So for the /blog path, it would match /blog and /blog?page=1 but not /blog/posts/asdf
    def regexp_string_for_path
      str = "^#{quoted_path}(\\?|$)"
      str.length > 128 ? limit_regexp_string(str) : str
    end

    private

    # rubocop:disable Metrics/LineLength
    # This method replaces appropriate number of characters in the beginning of the last segment
    # with a .* to limit the regexp string to 128 characters.
    # This helps avoid Google analytics' complaints.
    # Example /interviews/if-our-sins-are-punished-by-eternal-separation-from-god-why-did-jesus-only-have-to-suffer-momentary-separation
    # will become ^/interviews/.*our-sins-are-punished-by-eternal-separation-from-god-why-did-jesus-only-have-to-suffer-momentary-separation(\\?|$)
    # rubocop:enable Metrics/LineLength
    def limit_regexp_string(str)
      difference = str.length - 126 # we are adding 2 characters .* 126 helps us get that.
      path_segments = quoted_path.split('/')
      last_segment = path_segments.pop
      last_segment.slice!(0..difference - 1)
      path_segments.push '.*' + last_segment
      "^#{path_segments.join('/')}(\\?|$)"
    end

    # This escapes special characters in a string to prepare it for a regular expression
    # It undoes quoting the '-' because unquoting them doesn't seem to affect the result
    def quoted_path
      Regexp.quote(path).gsub('\\-', '-')
    end

    def lang_included?
      /lang=/ =~ path
    end
  end

  def format_date(date)
    date.to_date.to_s
  end
end
