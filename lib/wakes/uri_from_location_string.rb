# frozen_string_literal: true

class URIFromLocationString
  def self.generate(location_string)
    location_string = "http://#{location_string}" if URI(location_string).scheme.nil?
    URI(location_string)
  end

  def self.get_host_and_path(location_string)
    uri = generate(location_string)
    [uri.host, uri.request_uri]
  end
end
