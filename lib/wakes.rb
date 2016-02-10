# frozen_string_literal: true
require 'rails/engine'
require 'wakes/version'
require 'wakes/engine'
require 'wakes/configuration'
require 'wakes/redirect_mapper'

module Wakes
  def self.logger
    @logger || Rails.logger
  end

  def self.logger=(logger)
    @logger = logger
  end

  def self.table_name_prefix
    'wakes_'
  end

  def self.build(label:, wakeable: nil, path:, identifier: nil)
    logger.debug { "Building wake for #{label} at #{path}" }
    resource = Wakes::Resource.new(:label => label, :wakeable => wakeable, :identifier => identifier)
    resource.locations.build(:path => path, :canonical => true)
    resource
  end

  def self.create(*args)
    build(*args).tap(&:save)
  end

  def self.create!(*args)
    build(*args).tap(&:save!)
  end

  def self.redirect(source, target, label = nil)
    RedirectMapper.redirect(source, target, label)
  end
end
