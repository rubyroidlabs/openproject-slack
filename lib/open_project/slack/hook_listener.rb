class OpenProject::Slack::HookListener < Redmine::Hook::Listener
  def controller_wiki_edit_after_save(context = { })
    # return unless Setting.plugin_openproject_slack['post_wiki_updates'] == '1'

    project = context[:project]
    page = context[:page]

    user = page.content.author
    project_url = "<#{object_url project}|#{escape project}>"
    page_url = "<#{object_url page}|#{page.title}>"
    message = "[#{project_url}] #{page_url} updated by *#{user}*"

    channel = channel_for_project project
    url = Setting.plugin_openproject_slack['slack_url']

    return if channel.blank? || url.blank?

    attachment = nil
    if page.content.comments.present?
      attachment = {}
      attachment[:text] = "#{escape page.content.comments}"
    end

    OpenProject::Slack::Notifier.new.speak(message, channel: channel, attachment: attachment)
  end

  def redmine_slack_issues_new_after_save(context={})
    issue = context[:issue]

    channel = channel_for_project issue.project
    url = Setting.plugin_openproject_slack['slack_url']

    return if channel.blank? || url.blank?

    message = "[<#{object_url issue.project}|#{escape issue.project}>] #{escape issue.author} created <#{object_url issue}|#{escape issue}>#{mentions issue.description}"

    attachment = {}
    attachment[:text] = escape(issue.description) if issue.description.present?
    attachment[:fields] = [{
      title: I18n.t("field_status"),
      value: escape(issue.status.to_s),
      short: true
    }, {
      title: I18n.t("field_priority"),
      value: escape(issue.priority.to_s),
      short: true
    }, {
      title: I18n.t("field_assigned_to"),
      value: escape(issue.assigned_to.to_s),
      short: true
    }]

    attachment[:fields] << {
      title: I18n.t("field_watcher"),
      value: escape(issue.watcher_users.join(', ')),
      short: true
    } # if Setting.plugin_redmine_slack['display_watchers'] == 'yes'

    OpenProject::Slack::Notifier.new.speak(message, channel: channel, attachment: attachment)
  end

  def redmine_slack_issues_edit_after_save(context={})
    issue = context[:issue]
    journal = context[:journal]

    channel = channel_for_project(issue.project)
    url = Setting.plugin_openproject_slack['slack_url']

    return if channel.blank? || url.blank?

    message = "[<#{object_url issue.project}|#{escape issue.project}>] #{escape journal.user.to_s} updated <#{object_url issue}|#{escape issue}>#{mentions journal.notes}"

    attachment = {}
    attachment[:text] = escape(journal.notes) if journal.notes.present?

    attachment[:fields] = journal.details.map do |key, changeset|
      detail_to_hash(issue, key, changeset)
    end

    OpenProject::Slack::Notifier.new.speak(message, channel: channel, attachment: attachment)
  end

  private

  def escape(message)
    message.to_s.gsub("&", "&amp;").gsub("<", "&lt;").gsub(">", "&gt;")
  end

  def channel_for_project(project)
    channel = project.custom_values.
      joins(:custom_field).
      find_by(custom_fields: { name: OpenProject::Slack::SLACK_CHANNEL_LABEL })&.
      value

    channel ||= channel_for_project(project.parent) if project.parent.present?

    channel ||= Setting.plugin_openproject_slack['default_channel']

    channel
  end

  def default_url_options(repository, changeset)
    {
      controller: 'repositories',
      action: 'revision',
      id: repository.project,
      repository_id: repository.identifier_param,
      rev: changeset.revision,
      protocol: Setting.protocol
    }
  end

  def object_url(obj)
    if Setting.host_name.to_s =~ /\A(https?\:\/\/)?(.+?)(\:(\d+))?(\/.+)?\z/i
      host, port, prefix = $2, $4, $5
      Rails.application.routes.url_for(obj.event_url({
        host: host,
        protocol: Setting.protocol,
        port: port,
        script_name: prefix
      }))
    else
      Rails.application.routes.url_for(obj.event_url({
        host: Setting.host_name,
        protocol: Setting.protocol
      }))
    end
  end

  def mentions(text)
    return nil if text.blank?

    names = extract_usernames text
    names.present? ? "\nTo: " + names.join(', ') : nil
  end

  def extract_usernames(text = '')
    # slack usernames may only contain lowercase letters, numbers,
    # dashes and underscores and must start with a letter or number.
    text.scan(/@[a-z0-9][a-z0-9_\-]*/).uniq
  end

  def detail_to_hash(issue, key, changeset)
    method_name = if key =~ /_id$/
                    key.sub(/_id$/, '')
                  elsif key =~ /attachments_\d+/
                    key.sub(/_\d+/, '')
                  else
                    key
                  end
    title_key = "field_#{method_name}"

    hash = {
      title: I18n.t(title_key),
      short: true
    }

    value = if key =~ /_id$/
      escape(issue.send(method_name)) if issue.respond_to?(method_name)
    end

    value ||= escape(changeset.last)
    value = I18n.t('none') if value.blank?

    hash[:value] = value

    hash
  end
end
