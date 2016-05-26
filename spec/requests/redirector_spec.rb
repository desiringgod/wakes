# frozen_string_literal: true
require 'rails_helper'

RSpec.describe 'redirects' do
  let(:resource) { create(:resource) }

  describe 'basic redirects' do
    before do
      create(:location, :path => '/target', :canonical => true, :resource => resource)
      create(:location, :path => '/test', :canonical => false, :resource => resource)
    end

    it 'redirects when it should' do
      get '/test'

      expect(response).to redirect_to('/target')
      expect(response.headers['Turbolinks-Location']).to eq('/target')
    end

    it 'does not redirect when it should not redirect' do
      get '/target'

      expect(response).to have_http_status(:success)
      expect(response.headers['Turbolinks-Location']).to be_nil
    end
  end

  describe 'params handling' do
    before do
      create(:location, :path => '/es/target', :canonical => true, :resource => resource)
      create(:location, :path => '/test', :canonical => false, :resource => resource)
    end

    it 'respects specified params' do
      create(:location, :path => '/test?lang=es', :canonical => false, :resource => resource)

      get '/test?lang=es'
      expect(response).to redirect_to('/es/target')

      get '/test?page=3'
      expect(response).to redirect_to('/es/target?page=3')
    end

    it 'passes through arbitrary params' do
      get '/test?arbitrary=param'

      expect(response).to redirect_to('/es/target?arbitrary=param')
    end

    it 'handles both specified and arbitrary params' do
      create(:location, :path => '/test?page=es', :canonical => false, :resource => resource)

      get '/test?page=es&arbitrary=param&another=param'
      expect(response).to redirect_to('/es/target?arbitrary=param&another=param')

      get '/test?arbitrary=param&page=es&another=param'
      expect(response).to redirect_to('/es/target?arbitrary=param&another=param')
    end

    it 'handles both specified and arbitrary params when the specified param is part of the target' do
      create(:location, :path => '/test?lang=es&page=2', :canonical => false, :resource => resource)
      resource.canonical_location.update_attribute(:path, '/es/target?page=2')

      get '/test?lang=es&page=2&arbitrary=param&another=param'
      expect(response).to redirect_to('/es/target?page=2&arbitrary=param&another=param')

      get '/test?lang=es&arbitrary=param&page=2&another=param'
      expect(response).to redirect_to('/es/target?page=2&arbitrary=param&another=param')
    end

    it 'contains known ambiguity' do
      resource_one = create(:resource)
      create(:location, :path => '/target-one', :canonical => true, :resource => resource_one)
      create(:location, :path => '/test?page=2', :canonical => false, :resource => resource_one)

      resource_two = create(:resource)
      create(:location, :path => '/target-two', :canonical => true, :resource => resource_two)
      create(:location, :path => '/test?lang=es', :canonical => false, :resource => resource_two)

      get '/test?page=2&lang=es'
      expect(response.location).to be_in(['/target-two?page=2', '/target-one?lang=es'])
      expect(response.code).to eq('301')
    end
  end
end
