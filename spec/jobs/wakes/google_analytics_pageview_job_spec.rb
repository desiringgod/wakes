require 'rails_helper'

RSpec.describe Wakes::GoogleAnalyticsPageviewJob, :type => :job do
  let(:location) { create(:location, :path => '/articles/marriage-on-the-edge-of-eternity') }

  it 'uses PageviewCountUpdaterService to update the pageview count on the location' do
    service_double = double(Wakes::PageviewCountUpdaterService)
    expect(service_double).to receive(:update_pageview_count)
    expect(Wakes::PageviewCountUpdaterService).to receive(:new).with(location).and_return(service_double)

    described_class.perform_now(location)
  end

  it 'queues up the job as expected' do
    expect { described_class.perform_later(location) }
      .to have_enqueued_job(Wakes::GoogleAnalyticsPageviewJob).with(location).on_queue('wakes_metrics')
  end
end
