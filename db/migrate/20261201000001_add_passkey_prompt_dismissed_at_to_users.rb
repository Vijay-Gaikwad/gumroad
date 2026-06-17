class AddPasskeyPromptDismissedAtToUsers < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :passkey_prompt_dismissed_at, :datetime
  end
end
