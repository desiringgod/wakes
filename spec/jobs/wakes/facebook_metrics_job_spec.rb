# frozen_string_literal: true
require 'rails_helper'

RSpec.describe Wakes::FacebookMetricsJob, :type => :job do
  let(:location) { create(:location) }

  it 'uses FacebookCountUpdaterService to update the pageview count on the location' do
    service_double = double(Wakes::FacebookCountUpdaterService)
    expect(service_double).to receive(:update_facebook_count)
    expect(Wakes::FacebookCountUpdaterService).to receive(:new).with(location).and_return(service_double)

    described_class.perform_now(location)
  end

  it 'queues up the job as expected' do
    expect { described_class.perform_later(location) }
      .to have_enqueued_job(Wakes::FacebookMetricsJob).with(location).on_queue('wakes_metrics')
  end
end
