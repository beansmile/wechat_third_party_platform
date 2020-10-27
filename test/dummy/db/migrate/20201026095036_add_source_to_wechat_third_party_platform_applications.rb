# frozen_string_literal: true

class AddSourceToWechatThirdPartyPlatformApplications < ActiveRecord::Migration[6.0]
  def change
    add_column :wechat_third_party_platform_applications, :source, :integer, default: 0
  end
end
