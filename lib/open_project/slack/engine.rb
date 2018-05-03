# Prevent load-order problems in case openproject-plugins is listed after a plugin in the Gemfile
# or not at all
require 'open_project/plugins'

module OpenProject::Slack
  class Engine < ::Rails::Engine
    engine_name :openproject_slack

    include OpenProject::Plugins::ActsAsOpEngine

    register 'openproject-slack',
             author_url: 'https://openproject.org',
             requires_openproject: '>= 6.0.0',
             settings: {
              default: { slack_url: '', username: 'Openproject Notifier', icon: ':see_no_evil:' },
              partial: 'settings/slack'
             }
  end
end
