# frozen_string_literal: true

# This cop is returning a false positive.
class WakeableModel < ActiveRecord::Base
  include Wakeable
end

def custom_wakeable_class(parent_klass = WakeableModel, &block)
  klass = Object.const_set("MyClass#{Time.now.subsec.numerator}", Class.new(parent_klass))
  klass.class_eval(&block)
  klass
end
