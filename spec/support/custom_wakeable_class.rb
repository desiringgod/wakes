class WakeableModel < ActiveRecord::Base
  include Wakeable
end

def custom_wakeable_class(&block)
  klass = Object.const_set("MyClass#{Time.now.subsec.numerator}", Class.new(WakeableModel))
  klass.class_eval(&block)
  klass
end
