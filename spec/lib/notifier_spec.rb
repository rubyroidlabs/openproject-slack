require 'spec_helper'
require 'webmock/rspec'

describe OpenProject::Slack::Notifier do
  context 'when slack url is not specified' do
    before do
      Setting.plugin_openproject_slack['slack_url'] = nil
    end

    it 'should raise error' do
      expect { OpenProject::Slack::Notifier.new }.to raise_error(ArgumentError, /slack url/i)
    end
  end

  describe '#speak' do
    context 'when slack url is specified' do
      let(:url) { 'https://hooks.slack.com/services' }
      let(:message) { 'message' }

      before do
        stub_request(:post, url).to_return(status: 200, body: 'ok')
      end

      context 'by setting' do
        before do
          Setting.plugin_openproject_slack['slack_url'] = url
        end

        it 'should speak' do
          response = OpenProject::Slack::Notifier.new.speak(message)
          expect(response).to be_a(HTTP::Message)
        end
      end

      context 'by argument' do
        it 'should speak' do
          response = OpenProject::Slack::Notifier.new(url: url).speak(message)
          expect(response).to be_a(HTTP::Message)
        end
      end
    end
  end
end
