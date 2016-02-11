# frozen_string_literal: true
require 'json'
require 'httparty'

class Wakes::FacebookMetricsWrapper
  attr_reader :url

  def initialize(url)
    @url = url
  end

  def total_count
    metrics['total_count']
  end

  def metrics
    parsed_response
  end

  private

  # rubocop:disable Metrics/MethodLength
  def parsed_response
    attempts = 1
    begin
      make_request.parsed_response[0]
    rescue => e
      puts "Failed #{attempts} attempt(s) - #{e}"
      attempts += 1
      if attempts <= 3
        sleep 2
        retry
      else
        raise e
      end
    end
  end
  # rubocop:enable Metrics/MethodLength

  def make_request
    HTTParty.get 'https://api.facebook.com/method/fql.query',
                 :query => {
                   :format => 'json',
                   :query => fql
                 }
  end

  def fql
    "select commentsbox_count, \
    click_count, \
    total_count, \
    comment_count, \
    like_count, \
    share_count \
    from link_stat \
    where url=\"#{url}\""
  end
end
