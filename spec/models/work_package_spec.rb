require 'spec_helper'
require 'webmock/rspec'

describe WorkPackage do
  let(:url) { 'https://hooks.slack.com/services' }

  before do
    stub_request(:post, url).to_return(status: 200, body: 'ok')
    Setting.plugin_openproject_slack['slack_url'] = url
  end

  context 'when default channel is specified' do
    before do
      Setting.plugin_openproject_slack['default_channel'] = 'channel'
    end

    context 'when new work package is created' do
      let(:new_work_package) { FactoryGirl.build(:work_package) }

      it 'should call slack notifier' do
        expect_any_instance_of(OpenProject::Slack::Notifier).to receive(:speak)
        new_work_package.save
      end
    end

    context 'when existed work package is updated' do
      let(:work_package) { FactoryGirl.create(:work_package) }

      it 'should call slack notifier' do
        expect_any_instance_of(OpenProject::Slack::Notifier).to receive(:speak)
        work_package.touch
      end
    end
  end

  context 'when default channel is not specified' do
    before do
      Setting.plugin_openproject_slack['default_channel'] = nil
    end

    context 'when new work package is created' do
      let(:new_work_package) { FactoryGirl.build(:work_package) }

      it 'should not call slack notifier' do
        expect_any_instance_of(OpenProject::Slack::Notifier).not_to receive(:speak)
        new_work_package.save
      end
    end

    context 'when existed work package is updated' do
      let(:work_package) { FactoryGirl.create(:work_package) }

      it 'should not call slack notifier' do
        expect_any_instance_of(OpenProject::Slack::Notifier).not_to receive(:speak)
        work_package.touch
      end
    end
  end

end
