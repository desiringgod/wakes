require 'google/api_client'

class Wakes::GoogleAnalyticsApiWrapper
  def initialize
    authenticate!
  end

  def authenticate!
    @authentication_token ||= client.authorization = Signet::OAuth2::Client.new(
      :token_credential_uri => 'https://accounts.google.com/o/oauth2/token',
      :audience             => 'https://accounts.google.com/o/oauth2/token',
      :scope                => 'https://www.googleapis.com/auth/analytics.readonly',
      :issuer               => ENV['GOOGLE_API_CLIENT_EMAIL'],
      :signing_key          => OpenSSL::PKey::RSA.new(ENV['GOOGLE_API_PRIVATE_KEY'], 'notasecret'),
      :retries              => 3
    ).tap(&:fetch_access_token!)
  end

  def client
    @client ||= Google::APIClient.new(:application_name => 'Wakes Metrics', :application_version => Wakes::VERSION)
  end

  def api
    @api ||= client.discovered_api('analytics', 'v3')
  end

  def execute(request_hash)
    response = client.execute! request_hash
    handle_error(response.error_message) if response.error?
    response
  end

  # More precisely, this sums up the pageviews for this particular path and
  # any other paths with query strings
  # rubocop:disable Metrics/MethodLength
  def get_pageviews_for_path(path, start_date:, end_date:)
    result = execute(
      :api_method => api.data.ga.get,
      :parameters => {
        'ids' => "ga:#{ENV['GOOGLE_ANALYTICS_PROFILE_ID']}",
        'start-date' => start_date.to_s,
        'end-date' => end_date.to_s,
        'metrics' => 'ga:pageviews',
        'dimensions' => 'ga:pagePath',
        'filters' => PrepareFiltersForGAPagePath.new(path).filters,
        'sort' => '-ga:pageviews',
      }
    )
    result.data.totals_for_all_results['ga:pageviews'].to_i
  end
  # rubocop:enable Metrics/MethodLength

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

  def handle_error(message)
    case message
    when 'There was an internal error' then raise InternalError
    when 'There was a temporary error. Please try again later.' then raise TemporaryError
    when 'Daily Limit Exceeded' then raise DailyLimitExceededError
    when 'User Rate Limit Exceeded' then raise UserRateLimitExceededError
    else raise message
    end
  end

  class DailyLimitExceededError < StandardError; end
  class UserRateLimitExceededError < StandardError; end
  class InternalError < StandardError; end
  class TemporaryError < StandardError; end
end
