# frozen_string_literal: true

class CreateWechatThirdPartyPlatformApplications < ActiveRecord::Migration[6.0]
  def change
    create_table :wechat_third_party_platform_applications do |t|
      t.string :appid , index: { unique: true }
      t.integer :account_type
      t.integer :principal_type
      t.string :principal_name
      t.string :access_token
      t.string :refresh_token

      t.timestamps
    end
  end
end
