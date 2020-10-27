# frozen_string_literal: true

class AddRegisterIdWechatThirdPartyPlatformApplication < ActiveRecord::Migration[6.0]
  def change
    add_column :wechat_third_party_platform_applications, :register_id, :integer
    add_index :wechat_third_party_platform_applications, :register_id
  end
end
