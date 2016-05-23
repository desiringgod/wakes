# frozen_string_literal: true
require 'rails/engine'
require 'wakes/version'
require 'wakes/engine'
require 'wakes/configuration'
require 'wakes/redirect_mapper'
require 'wakes/middleware/redirector'

require 'redis-rails'
require 'redis-namespace'

module Wakes
  REDIS = Redis::Namespace.new(:wakes, :redis => Redis.new(:url => ENV[ENV['REDIS_PROVIDER'] || 'REDIS_URL']))

  def self.logger
    @logger || Rails.logger
  end

  def self.logger=(logger)
    @logger = logger
  end

  def self.table_name_prefix
    'wakes_'
  end

  def self.build(label:, wakeable: nil, host: nil, path:, identifier: nil)
    logger.debug { "Building wake for #{label} at #{path}" }
    resource = Wakes::Resource.new(:label => label, :wakeable => wakeable, :identifier => identifier)
    resource.locations.build(:host => host, :path => path, :canonical => true)
    resource
  end

  def self.create(*args)
    build(*args).tap(&:save)
  end

  def self.create!(*args)
    build(*args).tap(&:save!)
  end

  def self.redirect(source_path_or_url, target_path_or_url, label = nil)
    RedirectMapper.new(source_path_or_url, target_path_or_url, label)
  end

  def self.create_redis_graph
    Wakes::Resource.find_each(&:rebuild_redirect_graph)
  end

  def self.destroy_redis_graph
    if (keys = Wakes::REDIS.keys).present?
      Wakes::REDIS.del(*keys)
    end
    Wakes::Resource.find_each do |resource|
      resource.update_attribute(:legacy_paths_in_redis, nil)
    end
  end

  COLORS = {
    :black => "\e[30m",
    :red => "\e[31m",
    :green => "\e[32m",
    :yellow => "\e[33m",
    :blue => "\e[34m",
    :magenta => "\e[35m",
    :cyan => "\e[36m",
    :white => "\e[37m"
  }.freeze

  def self.color(color, string, bold: false)
    bold = bold ? "\e[1m" : ''

    if color = COLORS[color.to_sym]
      "#{bold}#{color}#{string}\e[0m"
    else
      string
    end
  end
end
