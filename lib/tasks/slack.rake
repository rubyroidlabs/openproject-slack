namespace :slack do
  desc "Send message to slack"
  task :speak => :environment do
    notifier = OpenProject::Slack::Notifier.new(url: ENV['HOOK'])
    notifier.speak(ENV['MESSAGE'], channel: ENV['CHANNEL'], attachment: ENV['ATTACHMENT'])
  end
end
