# frozen_string_literal: true

class CreateWechatThirdPartyPlatformTemplates < ActiveRecord::Migration[6.0]
  def change
    create_table :wechat_third_party_platform_templates do |t|
      t.string :template_id
      t.string :user_version
      t.string :user_desc
      t.string :draft_id

      t.timestamps
    end
  end
end
