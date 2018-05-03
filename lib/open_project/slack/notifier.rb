class OpenProject::Slack::Notifier
  def speak(msg, channel, attachment=nil, url=nil)
    url = Setting.plugin_openproject_slack['slack_url'] if url.blank?
    username = Setting.plugin_openproject_slack['username']
    icon = Setting.plugin_openproject_slack['icon']

    params = {
      text: msg,
      link_names: 1,
    }

    params[:username] = username if username
    params[:channel] = channel if channel

    params[:attachments] = [attachment] if attachment

    if icon && icon.present?
      if icon.start_with? ':'
        params[:icon_emoji] = icon
      else
        params[:icon_url] = icon
      end
    end

    begin
      client = HTTPClient.new
      client.ssl_config.cert_store.set_default_paths
      client.ssl_config.ssl_version = :auto
      client.post_async url, { payload: params.to_json }
    rescue Exception => e
      Rails.logger.warn("cannot connect to #{url}")
      Rails.logger.warn(e)
    end
  end
end
