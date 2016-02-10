# frozen_string_literal: true
require 'rails_helper'

RSpec.describe Wakes::RedirectMapper do
  let!(:resource) { create(:resource) }

  context 'target exists and source does not' do
    context 'target is canonical' do
      let!(:target) { create(:location, :canonical => true, :path => '/target', :resource => resource) }

      it 'creates a source as non-canonical' do
        described_class.redirect '/source', '/target'

        expect(resource).to have_wakes_graph(:canonical_location => '/target', :legacy_locations => ['/source'])
      end
    end
  end

  context 'source exists and target does not' do
    context 'source is canonical' do
      let!(:other) { create(:location, :canonical => false, :path => '/other', :resource => resource) }
      let!(:source) { create(:location, :canonical => true, :path => '/source', :resource => resource) }

      it 'creates target as canonical' do
        described_class.redirect '/source', '/target'

        expect(resource).to have_wakes_graph(:canonical_location => '/target',
                                             :legacy_locations => ['/source', '/other'])
      end
    end

    context 'source is noncanonical' do
      let!(:other) { create(:location, :canonical => true, :path => '/other', :resource => resource) }
      let!(:source) { create(:location, :canonical => false, :path => '/source', :resource => resource) }

      it 'creates target as canonical' do
        described_class.redirect '/source', '/target', 'New Label'

        expect(resource).to have_wakes_graph(:canonical_location => '/other')
        expect(Wakes::Location.find_by(:path => '/target').resource)
          .to have_wakes_graph(:canonical_location => '/target', :legacy_locations => ['/source'])
      end
    end
  end

  context 'target and source exist' do
    context 'on the same resource' do
      context 'target is canonical and source is not' do
        let!(:target) { create(:location, :canonical => true, :path => '/target', :resource => resource) }
        let!(:source) { create(:location, :canonical => false, :path => '/source', :resource => resource) }

        it 'then nothing needs to change' do
          described_class.redirect '/source', '/target'

          expect(resource).to have_wakes_graph(:canonical_location => '/target', :legacy_locations => ['/source'])
        end
      end

      context 'source is canonical and target is not' do
        let!(:source) { create(:location, :canonical => true, :path => '/source', :resource => resource) }
        let!(:target) { create(:location, :canonical => false, :path => '/target', :resource => resource) }

        it 'switches them' do
          described_class.redirect '/source', '/target'

          expect(resource).to have_wakes_graph(:canonical_location => '/target', :legacy_locations => ['/source'])
        end
      end

      context 'neither source nor target are canonical' do
        let!(:other) { create(:location, :canonical => true, :path => '/other', :resource => resource) }
        let!(:source) { create(:location, :canonical => false, :path => '/source', :resource => resource) }
        let!(:target) { create(:location, :canonical => false, :path => '/target', :resource => resource) }

        it 'sets them up on a new resource' do
          described_class.redirect '/source', '/target'

          expect(resource).to have_wakes_graph(:canonical_location => '/other')
          expect(Wakes::Location.find_by(:path => '/target').resource)
            .to have_wakes_graph(:canonical_location => '/target', :legacy_locations => ['/source'])
        end
      end
    end

    context 'on different resources' do
      let!(:source_resource) { create(:resource) }
      let!(:target_resource) { create(:resource) }

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
          described_class.redirect '/source', '/target'

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
          described_class.redirect '/source', '/target'

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
          described_class.redirect '/source', '/target'

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
          described_class.redirect '/source', '/target'

          expect(source_resource).to have_wakes_graph(:canonical_location => '/other-on-source')
          expect(target_resource).to have_wakes_graph(:canonical_location => '/other-on-target')
          expect(Wakes::Location.find_by(:path => '/target').resource)
            .to have_wakes_graph(:canonical_location => '/target', :legacy_locations => ['/source'])
        end
      end
    end
  end

  context 'neither target nor source exist' do
    it 'creates a new resource' do
      described_class.redirect '/source', '/target'

      expect(Wakes::Location.find_by(:path => '/target').resource)
        .to have_wakes_graph(:canonical_location => '/target', :legacy_locations => ['/source'])
    end
  end
end
