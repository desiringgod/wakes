# frozen_string_literal: true
class Wakes::ModelConfiguration
  class UnrecognizedConfigurationOption < StandardError; end
  attr_reader :configuration

  OPTIONS = [:has_many, :path, :label, :run_if, :dependents, :debug].freeze

  def initialize(&block)
    @configuration = {}

    instance_exec(&block)
  end

  def method_missing(name, *args, &block)
    if OPTIONS.include?(name)
      @configuration[name] = args.first || block
    else
      raise UnrecognizedConfigurationOption,
            "Unrecognized configuration option #{name}. Allowed options are #{OPTIONS.to_sentence}."
    end
  end

  def respond_to_missing?(method_name, include_private = false)
    OPTIONS.include?(method_name) || super
  end
end
