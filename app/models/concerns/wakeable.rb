module Wakeable
  extend ActiveSupport::Concern

  included do
    has_one :wakes_resource, :class_name => 'Wakes::Resource', :inverse_of => :wakeable, :as => :wakeable
    accepts_nested_attributes_for :wakes_resource

    after_create :initialize_wakes_graph

    after_update :update_wakes_graph
  end

  def initialize_wakes_graph
    wakes_resource = build_wakes_resource(:label => wakes_value_for(:label))
    wakes_resource.locations.build(:path => wakes_value_for(:path), :canonical => true)
    wakes_resource.save!
  end

  def update_wakes_graph
    if wakes_resource.label != wakes_value_for(:label)
      wakes_resource.update(:label => wakes_value_for(:label))
    end

    if wakes_resource.canonical_location.path != wakes_value_for(:path)
      wakes_resource.locations.update_all(:canonical => false)
      wakes_resource.locations.create(:path => wakes_value_for(:path), :canonical => true)
    end

    if (dependents = wakes_value_for(:dependents)).present?
      dependents.map(&:update_wakes_graph)
    end
  end

  def wakes_value_for(name)
    if value = self.class.wakes_configuration.configuration[name]
      if value.is_a? Proc
        instance_eval(&value)
      else
        self.send(value)
      end
    end
  end

  module ClassMethods
    attr_reader :wakes_configuration

    def wakes(&block)
      @wakes_configuration = Wakes::Configuration.new(&block)
    end
  end
end

class Wakes::Configuration
  attr_reader :configuration

  def initialize(&block)
    @configuration = {}

    instance_exec(&block)
  end

  def method_missing(name, *args, &block)
    @configuration[name] = args.first || block
  end
end
