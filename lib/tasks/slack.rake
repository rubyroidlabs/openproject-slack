namespace :slack do
  desc "Send message to slack"
  task :speak => :environment do
    notifier = OpenProject::Slack::Notifier.new
    notifier.speak(ENV['MESSAGE'], ENV['CHANNEL'], ENV['ATTACHMENT'], ENV['HOOK'])
  end
end
