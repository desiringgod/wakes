module Wakeable
  extend ActiveSupport::Concern

  def initialize_wakes_graph
    return if wakes_value_for(:run_if) == false

    if associated_options = wakes_value_for(:has_many)
      associated_options.each do |options|
        self.has_many_label = options[:label]
        self.has_many_path = options[:path_fragment]

        wakes_resource = wakes_resources.build(:label => wakes_value_for(:label), :identifier => options[:identifier])
        wakes_resource.locations.build(:path => wakes_value_for(:path), :canonical => true)
        wakes_resource.save!
      end
    else
      wakes_resource = build_wakes_resource(:label => wakes_value_for(:label))
      wakes_resource.locations.build(:path => wakes_value_for(:path), :canonical => true)
      wakes_resource.save!
    end
  end

  def update_wakes_graph
    return if wakes_value_for(:run_if) == false

    if associated_options = wakes_value_for(:has_many)
      associated_options.each do |options|
        self.has_many_label = options[:label]
        self.has_many_path = options[:path_fragment]

        wakes_resource = wakes_resources.find_by(:identifier => options[:identifier])

        if wakes_resource.label != wakes_value_for(:label)
          wakes_resource.update(:label => wakes_value_for(:label))
        end

        if wakes_resource.canonical_location.path != wakes_value_for(:path)
          wakes_resource.locations.update_all(:canonical => false)
          wakes_resource.locations.create(:path => wakes_value_for(:path), :canonical => true)
        end
      end
    else
      if wakes_resource.label != wakes_value_for(:label)
        wakes_resource.update(:label => wakes_value_for(:label))
      end

      if wakes_resource.canonical_location.path != wakes_value_for(:path)
        wakes_resource.locations.update_all(:canonical => false)
        wakes_resource.locations.create(:path => wakes_value_for(:path), :canonical => true)
      end
    end

    if (dependents = wakes_value_for(:dependents)).present?
      dependents.each(&:update_wakes_graph)
    end
  end

  def wakes_value_for(name)
    if value = self.class.wakes_configuration.configuration[name]
      if value.is_a? Proc
        instance_eval(&value)
      else
        send(value)
      end
    end
  end

  module ClassMethods
    attr_reader :wakes_configuration

    def wakes_value_for(name)
      if value = wakes_configuration.configuration[name]
        if value.is_a? Proc
          instance_eval(&value)
        else
          send(value)
        end
      end
    end

    def wakes(&block)
      attr_accessor :has_many_label, :has_many_path

      @wakes_configuration = Wakes::Configuration.new(&block)

      if wakes_value_for(:has_many)
        has_many :wakes_resources, :class_name => 'Wakes::Resource', :inverse_of => :wakeable, :as => :wakeable
        accepts_nested_attributes_for :wakes_resources
      else
        has_one :wakes_resource, :class_name => 'Wakes::Resource', :inverse_of => :wakeable, :as => :wakeable
        accepts_nested_attributes_for :wakes_resource
      end

      after_create :initialize_wakes_graph
      after_update :update_wakes_graph
    end
  end
end

class Wakes::Configuration
  class UnrecognizedConfigurationOption < StandardError; end
  attr_reader :configuration

  OPTIONS = [:has_many, :path, :label, :run_if, :dependents, :debug]

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
end
