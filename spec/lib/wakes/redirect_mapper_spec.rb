# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Wakes::RedirectMapper do
  context 'target exists and source does not' do
    let!(:resource) { create(:resource, :label => 'Only Resource') }

    context 'target is canonical' do
      let!(:target) { create(:location, :canonical => true, :path => '/target', :resource => resource) }

      it 'creates a source as non-canonical' do
        described_class.new '/source', '/target'

        expect(resource).to have_wakes_graph(:canonical_location => '/target', :legacy_locations => ['/source'])
      end
    end
  end

  context 'source exists and target does not' do
    let!(:resource) { create(:resource, :label => 'Only Resource') }

    context 'source is canonical' do
      let!(:other) { create(:location, :canonical => false, :path => '/other', :resource => resource) }
      let!(:source) { create(:location, :canonical => true, :path => '/source', :resource => resource) }

      it 'creates target as canonical' do
        described_class.new '/source', '/target'

        expect(resource).to have_wakes_graph(:canonical_location => '/target',
                                             :legacy_locations => ['/source', '/other'])
      end
    end

    context 'source is noncanonical' do
      let!(:other) { create(:location, :canonical => true, :path => '/other', :resource => resource) }
      let!(:source) { create(:location, :canonical => false, :path => '/source', :resource => resource) }

      it 'creates target as canonical' do
        described_class.new '/source', '/target', 'New Label'

        expect(resource).to have_wakes_graph(:canonical_location => '/other')
        expect(Wakes::Location.find_by(:host => nil, :path => '/target').resource)
          .to have_wakes_graph(:canonical_location => '/target', :legacy_locations => ['/source'])
      end
    end
  end

  context 'target and source exist' do
    context 'on the same resource' do
      let!(:resource) { create(:resource, :label => 'Only Resource') }

      context 'target is canonical and source is not; default host' do
        let!(:target) { create(:location, :canonical => true, :path => '/target', :resource => resource) }
        let!(:source) { create(:location, :canonical => false, :path => '/source', :resource => resource) }

        it 'then nothing needs to change' do
          described_class.new '/source', '/target'

          expect(resource).to have_wakes_graph(:canonical_location => '/target', :legacy_locations => ['/source'])
        end
      end

      context 'source is canonical and target is not' do
        let!(:source) { create(:location, :canonical => true, :path => '/source', :resource => resource) }
        let!(:target) { create(:location, :canonical => false, :path => '/target', :resource => resource) }

        it 'switches them' do
          described_class.new '/source', '/target'

          expect(resource).to have_wakes_graph(:canonical_location => '/target', :legacy_locations => ['/source'])
        end
      end

      context 'neither source nor target are canonical' do
        let!(:other) { create(:location, :canonical => true, :path => '/other', :resource => resource) }
        let!(:source) { create(:location, :canonical => false, :path => '/source', :resource => resource) }
        let!(:target) { create(:location, :canonical => false, :path => '/target', :resource => resource) }

        it 'sets them up on a new resource' do
          described_class.new '/source', '/target', 'New Label'

          expect(resource).to have_wakes_graph(:canonical_location => '/other')
          expect(Wakes::Location.find_by(:host => nil, :path => '/target').resource)
            .to have_wakes_graph(:canonical_location => '/target', :legacy_locations => ['/source'])
        end
      end
    end

    context 'on different resources' do
      let!(:source_resource) { create(:resource, :label => 'Source Resource') }
      let!(:target_resource) { create(:resource, :label => 'Target Resource') }

      context 'target and source are both canonical' do
        let!(:other_on_source) do
          create(:location, :canonical => false, :path => '/other-on-source', :resource => source_resource)
        end
        let!(:source) { create(:location, :canonical => true, :path => '/source', :resource => source_resource) }
        let!(:other_on_target) do
          create(:location, :canonical => false, :path => '/other-on-target', :resource => target_resource)
        end
        let!(:target) { create(:location, :canonical => true, :path => '/target', :resource => target_resource) }

        it 'points the entire source resource to the target resource' do
          described_class.new '/source', '/target'

          expect(target_resource)
            .to have_wakes_graph(:canonical_location => '/target',
                                 :legacy_locations => ['/source', '/other-on-source', '/other-on-target'])
          expect(Wakes::Resource.find_by(:id => source_resource.id)).to be_nil
        end
      end

      context 'target is canonical and source is not' do
        let!(:other_on_source) do
          create(:location, :canonical => true, :path => '/other-on-source', :resource => source_resource)
        end
        let!(:source) { create(:location, :canonical => false, :path => '/source', :resource => source_resource) }
        let!(:other_on_target) do
          create(:location, :canonical => false, :path => '/other-on-target', :resource => target_resource)
        end
        let!(:target) { create(:location, :canonical => true, :path => '/target', :resource => target_resource) }

        it 'points the source location to the target resource' do
          described_class.new '/source', '/target'

          expect(source_resource).to have_wakes_graph(:canonical_location => '/other-on-source')
          expect(target_resource).to have_wakes_graph(:canonical_location => '/target',
                                                      :legacy_locations => ['/source', '/other-on-target'])
        end
      end

      context 'source is canonical and target is not' do
        let!(:other_on_source) do
          create(:location, :canonical => false, :path => '/other-on-source', :resource => source_resource)
        end
        let!(:source) { create(:location, :canonical => true, :path => '/source', :resource => source_resource) }
        let!(:other_on_target) do
          create(:location, :canonical => true, :path => '/other-on-target', :resource => target_resource)
        end
        let!(:target) { create(:location, :canonical => false, :path => '/target', :resource => target_resource) }

        it 'adds the target location as the canonical location of the source resource' do
          described_class.new '/source', '/target'

          expect(target_resource).to have_wakes_graph(:canonical_location => '/other-on-target')
          expect(source_resource).to have_wakes_graph(:canonical_location => '/target',
                                                      :legacy_locations => ['/source', '/other-on-source'])
        end
      end

      context 'neither source nor target are canonical' do
        let!(:other_on_source) do
          create(:location, :canonical => true, :path => '/other-on-source', :resource => source_resource)
        end
        let!(:source) { create(:location, :canonical => false, :path => '/source', :resource => source_resource) }
        let!(:other_on_target) do
          create(:location, :canonical => true, :path => '/other-on-target', :resource => target_resource)
        end
        let!(:target) { create(:location, :canonical => false, :path => '/target', :resource => target_resource) }

        it 'creates a new resource with the source to target redirect set up' do
          described_class.new '/source', '/target', 'New Label'

          expect(source_resource).to have_wakes_graph(:canonical_location => '/other-on-source')
          expect(target_resource).to have_wakes_graph(:canonical_location => '/other-on-target')
          expect(Wakes::Location.find_by(:host => nil, :path => '/target').resource)
            .to have_wakes_graph(:canonical_location => '/target', :legacy_locations => ['/source'])
        end
      end
    end
  end

  context 'neither target nor source exist' do
    it 'creates a new resource' do
      described_class.new '/source', '/target', 'New Label'

      expect(Wakes::Location.find_by(:host => nil, :path => '/target').resource)
        .to have_wakes_graph(:canonical_location => '/target', :legacy_locations => ['/source'])
    end
  end

  describe 'handles non-default hosts' do
    context 'source is default, target is default' do
      it 'points the source location to the target resource' do
        described_class.new '/source', '/target', 'New Label'

        expect(Wakes::Location.find_by(:host => nil, :path => '/target').resource)
          .to have_wakes_graph(:canonical_location => '/target', :legacy_locations => ['/source'])
      end
    end

    context 'source is default, target is non-default' do
      it 'points the source location to the target resource' do
        described_class.new '/source', 'some.host/target', 'New Label'
        expect(Wakes::Location.find_by(:host => nil, :path => '/source').resource)
          .to have_wakes_graph(:canonical_location => 'some.host/target', :legacy_locations => ['/source'])
      end
    end

    context 'source is non-default, target is default' do
      it 'points the source location to the target resource' do
        described_class.new 'some.host/source', '/target', 'New Label'
        expect(Wakes::Location.find_by(:host => nil, :path => '/target').resource)
          .to have_wakes_graph(:canonical_location => '/target',
                               :legacy_locations => ['some.host/source'])
      end
    end

    context 'source is non-default, target is non-default' do
      it 'points the source location to the target resource' do
        described_class.new 'some.host/source', 'some.other.host/target', 'New Label'
        expect(Wakes::Location.find_by(:host => 'some.other.host', :path => '/target').resource)
          .to have_wakes_graph(:canonical_location => 'some.other.host/target',
                               :legacy_locations => ['some.host/source'])
      end
    end
  end

  context 'handles query strings' do
    it 'retains the query strings in the wakes graph' do
      described_class.new '/source?param=p1', '/target?key=value', 'New Label'

      expect(Wakes::Location.find_by(:host => nil, :path => '/source?param=p1').resource)
        .to have_wakes_graph(:canonical_location => '/target?key=value', :legacy_locations => ['/source?param=p1'])
    end
  end
end
