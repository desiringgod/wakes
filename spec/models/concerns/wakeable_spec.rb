require 'rails_helper'

class WakeableModel < ActiveRecord::Base
  include Wakeable
end

def custom_wakeable_class(&block)
  if defined?(MyClass)
    Object.send(:remove_const, :MyClass)
  end

  Object.const_set('MyClass', Class.new(WakeableModel))
  MyClass.class_eval(&block)
  MyClass
end

RSpec.describe Wakeable do
  describe 'configuration' do
    it 'accepts a block that is evaluated in the context of the instance' do
      model_class = custom_wakeable_class do
        wakes do
          some_wakes_config_option { my_method }
        end

        def my_method
          'my result'
        end
      end

      instance = model_class.new

      expect(instance.wakes_value_for(:some_wakes_config_option)).to eq('my result')
    end

    it 'accepts a method name that is sent to the instance' do
      model_class = custom_wakeable_class do
        wakes do
          some_wakes_config_option :my_method
        end

        def my_method
          'my result'
        end
      end

      instance = model_class.new

      expect(instance.wakes_value_for(:some_wakes_config_option)).to eq('my result')
    end

    it 'fails gracefully if value is not defined' do
      model_class = custom_wakeable_class do
        wakes do
        end
      end

      instance = model_class.new

      expect(instance.wakes_value_for(:some_wakes_config_option)).to be_nil
    end
  end

  describe 'parent' do
    it 'uses the passed value when processing dependents'
    it 'uses the configured value if available and not processing dependents'
    it 'uses the superclass value if no configured value and not processing dependents'
  end

  describe 'conditionals' do
    it 'runs the callbacks if run_if is true' do
      model_class = custom_wakeable_class do
        wakes do
          run_if { true }
          label :title
          path { "/#{title.parameterize}" }
        end
      end

      wakeable = model_class.create(:title => 'Some Title')
      expect(wakeable.wakes_resource).to have_wakes_graph(:canonical_location => '/some-title')

      wakeable.update!(:title => 'Some New Title')
      expect(wakeable.wakes_resource).to have_wakes_graph(:canonical_location => '/some-new-title', :legacy_locations => ['/some-title'])
    end

    it 'does not run the callbacks if run_if is false' do
      model_class = custom_wakeable_class do
        wakes do
          run_if { false }
          label :title
          path { "/#{title.parameterize}" }
        end
      end

      wakeable = model_class.create(:title => 'Some Title')
      expect(wakeable.wakes_resource).to be_nil

      wakeable.update!(:title => 'Some New Title')
      expect(wakeable.wakes_resource).to be_nil

    end
    it 'runs the callbacks if run_if is not set' do
      model_class = custom_wakeable_class do
        wakes do
          label :title
          path { "/#{title.parameterize}" }
        end
      end

      wakeable = model_class.create(:title => 'Some Title')
      expect(wakeable.wakes_resource).to have_wakes_graph(:canonical_location => '/some-title')

      wakeable.update!(:title => 'Some New Title')
      expect(wakeable.wakes_resource).to have_wakes_graph(:canonical_location => '/some-new-title', :legacy_locations => ['/some-title'])
    end
  end


  context 'a fully configured model' do
    before do
      @model_class = custom_wakeable_class do
        belongs_to :parent, :class_name => name
        has_many :children, :class_name => name, :foreign_key => :parent_id

        wakes do
          label :title
          dependents :children
          path do
            if parent.present?
              "/#{parent.title.parameterize}/#{title.parameterize}"
            else
              "/#{title.parameterize}"
            end
          end
        end
      end
    end

    describe 'on create' do
      it 'sets up a new Wakes::Resource and Wakes::Location' do
        wakeable = @model_class.create(:title => 'A Wakeable Model')

        expect(wakeable.wakes_resource).to be_a(Wakes::Resource)
        expect(wakeable.wakes_resource.label).to eq(wakeable.title)

        wakes_location = wakeable.wakes_resource.canonical_location
        expect(wakes_location).to be_a(Wakes::Location)
        expect(wakes_location.path).to eq('/a-wakeable-model')
      end
    end

    describe 'on update' do
      it 'creates a new canonical location on path change' do
        wakeable = @model_class.create(:title => 'Some Title')

        wakeable.update!(:title => 'Some New Title')

        expect(wakeable.wakes_resource).to have_wakes_graph(:canonical_location => '/some-new-title', :legacy_locations => ['/some-title'])
      end

      it 'changes the Wakes::Resource label on title change' do
        wakeable = @model_class.create(:title => 'Some Title')

        wakeable.update!(:title => 'Some New Title')

        expect(wakeable.wakes_resource.label).to eq('Some New Title')
      end

      it 'creates new canonical locations on parent title change' do
        parent_wakeable = @model_class.create(:title => 'Some Title')
        child_wakeable_one = @model_class.create(:title => 'One', :parent => parent_wakeable)
        child_wakeable_two = @model_class.create(:title => 'Two', :parent => parent_wakeable)

        parent_wakeable.update!(:title => 'Some New Title')

        expect(parent_wakeable.wakes_resource).to have_wakes_graph(:canonical_location => '/some-new-title', :legacy_locations => ['/some-title'])
        expect(child_wakeable_one.wakes_resource).to have_wakes_graph(:canonical_location => '/some-new-title/one', :legacy_locations => ['/some-title/one'])
        expect(child_wakeable_two.wakes_resource).to have_wakes_graph(:canonical_location => '/some-new-title/two', :legacy_locations => ['/some-title/two'])
      end
    end
  end
end
