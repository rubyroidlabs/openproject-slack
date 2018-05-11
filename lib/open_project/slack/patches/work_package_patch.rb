module OpenProject::Slack::Patches::WorkPackagePatch
  def self.included(base)
    base.class_eval do
      include InstanceMethods

      after_create :create_from_issue
      after_save :save_from_issue
    end
  end

  module InstanceMethods

    private

    def create_from_issue
      @create_already_fired = true
      context = { issue: self }
      Redmine::Hook.call_hook(:redmine_slack_issues_new_after_save, context)
      true
    end

    def save_from_issue
      if @create_already_fired.blank? && current_journal.present?
        context = { issue: self, journal: current_journal }
        Redmine::Hook.call_hook(:redmine_slack_issues_edit_after_save, context)
      end
      true
    end
    
  end
end

WorkPackage.send(:include, OpenProject::Slack::Patches::WorkPackagePatch)
