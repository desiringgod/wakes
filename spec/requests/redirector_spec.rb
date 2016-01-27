# frozen_string_literal: true
require 'rails_helper'

RSpec.describe 'redirects' do
  before do
    resource = create(:resource)
    create(:location, :path => '/target', :canonical => true, :resource => resource)
    create(:location, :path => '/test', :canonical => false, :resource => resource)
  end

  it 'redirects when it should' do
    get '/test'

    expect(response).to redirect_to('/target')
  end

  it 'does not redirect when it should not redirect' do
    get '/target'

    expect(response).to have_http_status(:success)
  end
end
