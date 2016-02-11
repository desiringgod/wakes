# frozen_string_literal: true
require 'rails_helper'

RSpec.describe Wakes::UpdateFacebookMetricsJob, :type => :job do
  let!(:locations) { create_list(:location, 10) }

  it 'uses FacebookCountUpdaterService to update the pageview count on the location' do
    service_double = double(Wakes::FacebookCountUpdaterService)
    expect(Wakes::FacebookCountUpdaterService)
      .to receive(:new).with(locations).and_return(service_double)
    expect(service_double).to receive(:update_facebook_count)
    described_class.perform_now(locations)
  end

  it 'queues up the job as expected' do
    expect { described_class.perform_later(locations) }
      .to have_enqueued_job(Wakes::UpdateFacebookMetricsJob).on_queue('wakes_facebook_metrics')
  end
end
