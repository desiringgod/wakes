# frozen_string_literal: true
require 'rails_helper'

RSpec.describe Wakeable do
  describe 'configuration' do
    it 'accepts a block that is evaluated in the context of the instance' do
      model_class = custom_wakeable_class do
        wakes do
          label { my_method }
        end

        def my_method
          'my result'
        end
      end

      instance = model_class.new

      expect(instance.wakes_value_for(:label)).to eq('my result')
    end

    it 'accepts a method name that is sent to the instance' do
      model_class = custom_wakeable_class do
        wakes do
          label :my_method
        end

        def my_method
          'my result'
        end
      end

      instance = model_class.new

      expect(instance.wakes_value_for(:label)).to eq('my result')
    end

    it 'fails gracefully if value is not defined' do
      model_class = custom_wakeable_class do
        wakes do
        end
      end

      instance = model_class.new

      expect(instance.wakes_value_for(:label)).to be_nil
    end

    it 'raises an error if the configuration option is not recognized' do
      expect do
        custom_wakeable_class do
          wakes do
            some_unrecognized_option { true }
          end
        end
      end.to raise_error(Wakes::ModelConfiguration::UnrecognizedConfigurationOption)
    end
  end

  describe 'has_many' do
    it 'has_one by default' do
      model_class = custom_wakeable_class do
        wakes do
          label :title
          path { "/#{title.parameterize}" }
        end
      end

      wakeable = model_class.create(:title => 'Some Title')
      expect(wakeable).to respond_to(:wakes_resource)
    end

    context 'has_many specified' do
      let(:model_class) do
        custom_wakeable_class do
          wakes do
            has_many do
              [
                {
                  :label => 'One',
                  :identifier => 'one',
                  :path_fragment => 'one'
                },
                {
                  :label => 'Two',
                  :identifier => 'two',
                  :path_fragment => 'two'
                }
              ]
            end
            label { "#{has_many_label} #{title}" }
            path { "/#{has_many_path}/#{title.parameterize}" }
          end
        end
      end

      describe 'on create' do
        it 'sets up the new Wakes::Resource and Wakes::Location' do
          wakeable = model_class.create(:title => 'A Wakeable Model')

          expect(wakeable.wakes_resources.first).to be_a(Wakes::Resource)
          expect(wakeable.wakes_resources.pluck(:label)).to include('One A Wakeable Model', 'Two A Wakeable Model')
          paths = wakeable.wakes_resources.map(&:locations).map(&:first).map(&:path)
          expect(paths).to include('/one/a-wakeable-model', '/two/a-wakeable-model')
        end
      end

      describe 'on update' do
        it 'creates new canonical locations on path change' do
          wakeable = model_class.create(:title => 'Some Title')

          wakeable.update!(:title => 'Some New Title')

          one = wakeable.wakes_resources.find_by(:identifier => 'one')
          expect(one).to have_wakes_graph(:canonical_location => '/one/some-new-title',
                                          :legacy_locations => ['/one/some-title'])

          two = wakeable.wakes_resources.find_by(:identifier => 'two')
          expect(two).to have_wakes_graph(:canonical_location => '/two/some-new-title',
                                          :legacy_locations => ['/two/some-title'])
        end

        it 'initializes a new wakes graph if for some reason none exists' do
          wakeable = model_class.create(:title => 'Some Title')
          wakeable.wakes_resources.destroy_all

          wakeable.reload

          wakeable.update!(:title => 'Some New Title')

          one = wakeable.wakes_resources.find_by(:identifier => 'one')
          expect(one).to have_wakes_graph(:canonical_location => '/one/some-new-title')

          two = wakeable.wakes_resources.find_by(:identifier => 'two')
          expect(two).to have_wakes_graph(:canonical_location => '/two/some-new-title')
        end
      end
    end
  end

  describe 'inheritance' do
    context 'parent has wakes and child does not' do
      let!(:parent_model_class) do
        custom_wakeable_class do
          wakes do
            label :title
            path { "/#{title.parameterize}" }
          end
        end
      end

      let!(:child_model_class) do
        custom_wakeable_class(parent_model_class) do
        end
      end

      it 'applies the parent configuration to the child' do
        wakeable = child_model_class.create(:title => 'A Wakeable Model')

        expect(wakeable.wakes_resource).to be_a(Wakes::Resource)
        expect(wakeable.wakes_resource.label).to eq('A Wakeable Model')
        expect(wakeable.wakes_resource).to have_wakes_graph(:canonical_location => '/a-wakeable-model')
      end

      it 'applies the parent configuration to the parent' do
        wakeable = parent_model_class.create(:title => 'A Wakeable Model')

        expect(wakeable.wakes_resource).to be_a(Wakes::Resource)
        expect(wakeable.wakes_resource.label).to eq('A Wakeable Model')
        expect(wakeable.wakes_resource).to have_wakes_graph(:canonical_location => '/a-wakeable-model')
      end
    end

    context 'parent and child both have wakes' do
      let!(:parent_model_class) do
        custom_wakeable_class do
          wakes do
            label { "Parent #{title}" }
            path { "/parent/#{title.parameterize}" }
          end
        end
      end

      let!(:child_model_class) do
        custom_wakeable_class(parent_model_class) do
          wakes do
            label { "Child #{title}" }
            path { "/child/#{title.parameterize}" }
          end
        end
      end

      it 'applies the child configuration to the child' do
        wakeable = child_model_class.create(:title => 'A Wakeable Model')

        expect(wakeable.wakes_resource).to be_a(Wakes::Resource)
        expect(wakeable.wakes_resource.label).to eq('Child A Wakeable Model')
        expect(wakeable.wakes_resource).to have_wakes_graph(:canonical_location => '/child/a-wakeable-model')
      end

      it 'applies the parent configuration to the parent' do
        wakeable = parent_model_class.create(:title => 'A Wakeable Model')

        expect(wakeable.wakes_resource).to be_a(Wakes::Resource)
        expect(wakeable.wakes_resource.label).to eq('Parent A Wakeable Model')
        expect(wakeable.wakes_resource).to have_wakes_graph(:canonical_location => '/parent/a-wakeable-model')
      end
    end

    context 'child has wakes and parent does not' do
      let!(:parent_model_class) do
        custom_wakeable_class do
        end
      end

      let!(:child_model_class) do
        custom_wakeable_class(parent_model_class) do
          wakes do
            label :title
            path { "/#{title.parameterize}" }
          end
        end
      end

      it 'applies the child configuration to the child' do
        wakeable = child_model_class.create(:title => 'A Wakeable Model')

        expect(wakeable.wakes_resource).to be_a(Wakes::Resource)
        expect(wakeable.wakes_resource.label).to eq('A Wakeable Model')
        expect(wakeable.wakes_resource).to have_wakes_graph(:canonical_location => '/a-wakeable-model')
      end

      it 'applies no configuration to the parent' do
        wakeable = parent_model_class.create(:title => 'A Wakeable Model')

        expect(wakeable).to_not respond_to(:wakes_resource)
      end
    end
  end

  describe '#raw_aggregate_pageview_count' do
    it 'returns the count from the one resource if there is just one' do
      model_class = custom_wakeable_class do
        wakes do
          label :title
          path { "/#{title.parameterize}" }
        end
      end

      wakeable = model_class.create(:title => 'Some Title')

      wakeable.wakes_resource.update(:pageview_count => 3)

      expect(wakeable.raw_aggregate_pageview_count).to eq(3)
    end

    it 'adds up all the resources if there are multiple' do
      model_class = custom_wakeable_class do
        wakes do
          has_many do
            [
              {
                :label => 'One',
                :identifier => 'one',
                :path_fragment => 'one'
              },
              {
                :label => 'Two',
                :identifier => 'two',
                :path_fragment => 'two'
              }
            ]
          end
          label { "#{has_many_label} #{title}" }
          path { "/#{has_many_path}/#{title.parameterize}" }
        end
      end
      wakeable = model_class.create(:title => 'A Wakeable Model')

      wakeable.wakes_resources.first.update(:pageview_count => 3)
      wakeable.wakes_resources.last.update(:pageview_count => 4)

      expect(wakeable.raw_aggregate_pageview_count).to eq(7)
    end
  end

  describe '#raw_aggregate_facebook_count' do
    it 'returns the count from the one resource if there is just one' do
      model_class = custom_wakeable_class do
        wakes do
          label :title
          path { "/#{title.parameterize}" }
        end
      end

      wakeable = model_class.create(:title => 'Some Title')

      wakeable.wakes_resource.update(:facebook_count => 3)

      expect(wakeable.raw_aggregate_facebook_count).to eq(3)
    end

    it 'adds up all the facebook_count of all resources if there are multiple' do
      model_class = custom_wakeable_class do
        wakes do
          has_many do
            [
              {
                :label => 'One',
                :identifier => 'one',
                :path_fragment => 'one'
              },
              {
                :label => 'Two',
                :identifier => 'two',
                :path_fragment => 'two'
              }
            ]
          end
          label { "#{has_many_label} #{title}" }
          path { "/#{has_many_path}/#{title.parameterize}" }
        end
      end
      wakeable = model_class.create(:title => 'A Wakeable Model')

      wakeable.wakes_resources.first.update(:facebook_count => 3)
      wakeable.wakes_resources.last.update(:facebook_count => 4)

      expect(wakeable.raw_aggregate_facebook_count).to eq(7)
    end
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
      expect(wakeable.wakes_resource).to have_wakes_graph(:canonical_location => '/some-new-title',
                                                          :legacy_locations => ['/some-title'])
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
      expect(wakeable.wakes_resource).to have_wakes_graph(:canonical_location => '/some-new-title',
                                                          :legacy_locations => ['/some-title'])
    end

    it 'properly gates dependents' do
      model_class = custom_wakeable_class do
        belongs_to :parent, :class_name => name
        has_many :children, :class_name => name, :foreign_key => :parent_id

        wakes do
          run_if do
            title != 'Disabled'
          end
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

      parent_wakeable = model_class.create(:title => 'Some Title')
      enabled_child = model_class.create(:title => 'Enabled', :parent => parent_wakeable)
      disabled_child = model_class.create(:title => 'Disabled', :parent => parent_wakeable)

      expect(parent_wakeable.wakes_resource).to be_present
      expect(enabled_child.wakes_resource).to be_present
      expect(disabled_child.wakes_resource).to_not be_present

      parent_wakeable.update!(:title => 'Some New Title')

      expect(parent_wakeable.reload.wakes_resource).to be_present
      expect(enabled_child.reload.wakes_resource).to be_present
      expect(disabled_child.reload.wakes_resource).to_not be_present
    end
  end

  context 'a fully configured model' do
    let(:model_class) do
      custom_wakeable_class do
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
        wakeable = model_class.create(:title => 'A Wakeable Model')

        expect(wakeable.wakes_resource).to be_a(Wakes::Resource)
        expect(wakeable.wakes_resource.label).to eq(wakeable.title)

        wakes_location = wakeable.wakes_resource.canonical_location
        expect(wakes_location).to be_a(Wakes::Location)
        expect(wakes_location.path).to eq('/a-wakeable-model')
      end
    end

    describe 'on update' do
      it 'creates a new canonical location on path change' do
        wakeable = model_class.create(:title => 'Some Title')

        wakeable.update!(:title => 'Some New Title')

        expect(wakeable.wakes_resource).to have_wakes_graph(:canonical_location => '/some-new-title',
                                                            :legacy_locations => ['/some-title'])
      end

      it 'changes the Wakes::Resource label on title change' do
        wakeable = model_class.create(:title => 'Some Title')

        wakeable.update!(:title => 'Some New Title')

        expect(wakeable.wakes_resource.label).to eq('Some New Title')
      end

      it 'creates new canonical locations on parent title change' do
        parent_wakeable = model_class.create(:title => 'Some Title')
        child_wakeable_one = model_class.create(:title => 'One', :parent => parent_wakeable)
        child_wakeable_two = model_class.create(:title => 'Two', :parent => parent_wakeable)

        parent_wakeable.update!(:title => 'Some New Title')

        expect(parent_wakeable.wakes_resource).to have_wakes_graph(:canonical_location => '/some-new-title',
                                                                   :legacy_locations => ['/some-title'])
        expect(child_wakeable_one.wakes_resource).to have_wakes_graph(:canonical_location => '/some-new-title/one',
                                                                      :legacy_locations => ['/some-title/one'])
        expect(child_wakeable_two.wakes_resource).to have_wakes_graph(:canonical_location => '/some-new-title/two',
                                                                      :legacy_locations => ['/some-title/two'])
      end

      it 'initializes a new wakes graph if for some reason none exists' do
        wakeable = model_class.create(:title => 'Some Title')
        wakeable.wakes_resource.destroy

        wakeable.reload

        wakeable.update!(:title => 'Some New Title')

        expect(wakeable.wakes_resource).to have_wakes_graph(:canonical_location => '/some-new-title')
      end
    end

    describe 'on destroy' do
      it 'destroys the wakes resource and wakes locations' do
        wakeable = model_class.create(:title => 'Some Title')
        resource = wakeable.wakes_resource
        location = resource.canonical_location

        expect(resource).to be_a(Wakes::Resource)
        expect(location).to be_a(Wakes::Location)

        wakeable.destroy

        expect(Wakes::Resource.find_by(:id => resource.id)).to be_nil
        expect(Wakes::Location.find_by(:id => location.id)).to be_nil
      end
    end
  end

  describe 'redirects' do
    it 'updates redirects on save' do
      model_class = custom_wakeable_class do
        wakes do
          label :title
          path { "/#{title.parameterize}" }
        end
      end

      wakeable = model_class.create(:title => 'Some Title')
      wakeable.title = 'Some New Title'
      wakeable.save
      expect(Wakes::REDIS.get('/some-title')).to eq('/some-new-title')
    end
  end

  describe '::wakes_enabled?' do
    let(:model_class) do
      custom_wakeable_class do
        wakes do
          label :title
          path { "/#{title.parameterize}" }
        end
      end
    end

    let(:wakeable) { model_class.new }

    context 'when Wakes.configuration.enabled is false' do
      it 'returns false' do
        Wakes.configuration.enabled = false

        expect(wakeable.wakes_enabled?).to be false
        Wakes.configuration.enabled = true
      end
    end

    context 'when Wakes.configuration.enabled is true' do
      it 'falls back to the value of run_if option in the model configuration block' do
        Wakes.configuration.enabled = true

        allow(wakeable).to receive(:wakes_value_for).with(:run_if).and_return(true)
        expect(wakeable.wakes_enabled?).to be true

        allow(wakeable).to receive(:wakes_value_for).with(:run_if).and_return(false)
        expect(wakeable.wakes_enabled?).to be false
        Wakes.configuration.enabled = true
      end
    end
  end
end
