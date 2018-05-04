class CreateSlackChannelCustomField < ActiveRecord::Migration[5.0]
  def up
    CustomField.create!(params)
  end

  def down
    CustomField.find_by(name: params[:name])&.destroy
  end

  private

  def params
    {
      type: 'ProjectCustomField',
      field_format: 'text', 
      name: OpenProject::Slack::SLACK_CHANNEL_LABEL
    }
  end
end

