# frozen_string_literal: true

class CreateWechatThirdPartyPlatformTesters < ActiveRecord::Migration[6.0]
  def change
    create_table :wechat_third_party_platform_testers do |t|
      t.string :wechat_id
      t.string :userstr
      t.integer :application

      t.timestamps
    end

    add_index :wechat_third_party_platform_testers, :application_id
  end
end
