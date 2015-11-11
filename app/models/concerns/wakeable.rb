module Wakeable
  extend ActiveSupport::Concern

  def wakes_value_for(name)
    if value = self.class.wakes_configuration.configuration[name]
      if value.is_a? Proc
        instance_eval(&value)
      else
        send(value)
      end
    end
  end

  def update_wakes_resource_label(wakes_resource)
    if wakes_resource.label != wakes_value_for(:label)
      wakes_resource.update(:label => wakes_value_for(:label))
    end
  end

  def update_wakes_resource_canonical_location(wakes_resource)
    if wakes_resource.canonical_location.path != wakes_value_for(:path)
      wakes_resource.locations.update_all(:canonical => false)
      wakes_resource.locations.create(:path => wakes_value_for(:path), :canonical => true)
    end
  end

  def update_dependents
    if (dependents = wakes_value_for(:dependents)).present?
      dependents.select(&:wakes_enabled?).each(&:update_wakes_graph)
    end
  end

  def wakes_enabled?
    wakes_value_for(:run_if) != false
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
      @wakes_configuration = Wakes::Configuration.new(&block)

      include wakes_value_for(:has_many) ? Wakeable::HasMany : Wakeable::HasOne

      after_create :initialize_wakes_graph, :if => :wakes_enabled?
      after_update :update_wakes_graph, :if => :wakes_enabled?
    end
  end
end
