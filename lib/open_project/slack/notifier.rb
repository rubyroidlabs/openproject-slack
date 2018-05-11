require 'httpclient'

class OpenProject::Slack::Notifier
  attr_reader :slack_url, :username, :params

  def initialize(url: nil)
    @slack_url = url || Setting.plugin_openproject_slack['slack_url']
    raise ArgumentError, 'slack url is blank' if slack_url.blank?

    @username = Setting.plugin_openproject_slack['username']
    @params = { link_names: 1, username: username }

    icon = Setting.plugin_openproject_slack['icon']
    if icon && icon.present?
      icon_key = icon.start_with?(':') ? :icon_emoji : :icon_url
      params[icon_key] = icon
    end

    @client = HTTPClient.new
    @client.ssl_config.cert_store.set_default_paths
    @client.ssl_config.ssl_version = :auto
  end

  def speak(message, channel: nil, attachment: nil)
    params[:text] = message
    params[:channel] = channel if channel.present?
    params[:attachments] = [attachment] if attachment.present?

    begin
      @client.post(slack_url, { payload: params.to_json })
    rescue SocketError => e
      Rails.logger.warn(e)
    end
  end
end
