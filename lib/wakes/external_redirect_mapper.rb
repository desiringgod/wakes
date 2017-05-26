# frozen_string_literal: true

module Wakes
  MAX_REDIRECTS = 10

  class ExternalRedirectMapper
    def initialize(url)
      @redirecting_uris = []
      @uri = URI(url)
    end

    def resource
      resolve_target&.resource
    end

    private

    # rubocop:disable MethodLength
    def resolve_target
      target_location = Wakes::Location.find_by(:host => host(@uri), :path => path(@uri))

      redirects = 0
      while target_location.nil? && expanded_url(@uri).present? && redirects < MAX_REDIRECTS
        @redirecting_uris << @uri
        target_location = Wakes::Location
                          .find_by(:host => host(expanded_url(@uri)), :path => path(expanded_url(@uri)))
                          &.resource&.canonical_location
        @uri = URI(expanded_url(@uri))
        redirects += 1
      end
      setup_redirects(target_location)
      target_location
    end
    # rubocop:enable MethodLength

    def setup_redirects(target_location)
      return if target_location.nil?
      @redirecting_uris
        .compact
        .reject { |source| is_internal_host? host(source) }
        .each { |source| Wakes.redirect source.to_s, target_location.path_or_url }
    end

    def expanded_url(uri)
      @expanded_url ||= {}
      @expanded_url[uri] ||= begin
        new_url = Net::HTTP.new(uri.host, uri.port)
                           .tap { |http| http.use_ssl = uri.scheme == 'https' }
                           .get(uri.path == '' ? '/' : uri.path)
                           .header['location']
        absolute_url(uri.scheme, uri.host, URI.encode(new_url.to_s))
      end
    end

    def absolute_url(scheme, host, path)
      if path.present? && URI(path).host.nil?
        "#{scheme}://#{host}#{path}"
      else
        path
      end
    end

    def host(url)
      host = URI(url).host
      host = host == ENV['DEFAULT_HOST'] ? nil : host
      host
    end

    def path(url)
      uri = URI(url)

      # remove trailing slashes except for root
      path = if ['/', ''].include? uri.path
               '/'
             else
               uri.path.sub(%r{/$}, '')
             end

      params = Rack::Utils.parse_nested_query uri.query
      params['lang'].present? ? "#{path}?lang=#{params['lang']}" : path
    end

    def is_internal_host?(host)
      return true if host.nil?
      if Wakes.configuration.internal_hosts.is_a?(Regexp)
        host =~ Wakes.configuration.internal_hosts
      elsif Wakes.configuration.internal_hosts.is_a?(Array)
        Wakes.configuration.internal_hosts.any? { |s| s.casecmp(host).zero? }
      else
        host == Wakes.configuration.internal_hosts
      end
    end
  end
end
