# frozen_string_literal: true

require 'json'
require 'httparty'

class Wakes::FacebookMetricsWrapper
  include HTTParty
  class FacebookError < StandardError; end
  class FacebookNullResponse < StandardError; end
  class FacebookRateLimitExceeded < StandardError; end
  API_URL = 'https://graph.facebook.com/v2.8'
  attr_reader :urls

  def initialize(*urls)
    @urls = urls.flatten
  end

  def share_counts
    {}.tap do |hash|
      individual_responses.map do |r|
        begin
          hash[r['id']] = r.fetch('share').fetch('share_count')
        rescue KeyError
          # Some urls can have no 'share' keys. This is generally in the case when the url isn't valid.
          Rails.logger.warn "Share count not received for #{r['id']}. Response is: #{r}"
          hash[r['id']] = nil
        end
      end
    end
  end

  private

  def individual_responses
    [].tap do |array|
      parsed_batch_response.each do |individual_response|
        raise FacebookNullResponse, 'one of the response is null' if individual_response.nil?
        parsed_individual_response = JSON.parse(individual_response['body'])
        array << parsed_individual_response
      end
    end
  end

  def parsed_batch_response
    @parsed_response ||= make_request.parsed_response.tap do |response|
      raise_exceptions_if_required(response)
    end
  end

  def raise_exceptions_if_required(response)
    return nil unless response.is_a?(Hash) && response['error']
    raise FacebookRateLimitExceeded, response['error']['message'] if response['error']['code'] == 4
    raise FacebookError,
          "Message: #{response['error']['message']}, "\
          "Code: #{response['error']['code']}, " \
          "Type: #{response['error']['type']}"
  end

  def make_request
    retries(3) do
      self.class.post API_URL,
                      :body => {'batch' => batched_url_requests,
                                'access_token' => ENV['FACEBOOK_API_TOKEN'],
                                'include_headers' => false}
    end
  end

  def batched_url_requests
    [].tap do |array|
      urls.each do |url|
        array << {'method' => 'GET', 'relative_url' => "?id=#{url}"}
      end
    end.to_json
  end

  # rubocop:disable Metrics/MethodLength
  def retries(times)
    attempts = 0
    begin
      yield
    rescue => e
      attempts += 1
      puts "Failed #{attempts} attempt(s) - #{e}"
      if attempts >= times
        raise e
      else
        add_delay; retry
      end
    end
  end

  def add_delay
    sleep 2
  end
  # rubocop:enable Metrics/MethodLength
end
