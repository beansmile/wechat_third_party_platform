# frozen_string_literal: true

class WechatThirdPartyPlatform::SetWeappSupportVersionJob < ApplicationJob
  def perform(application, version)
    resp = application.client.setweappsupportversion(version: version)
    raise "设置最低基础库版本失败：#{resp["errmsg"]}" if resp["errcode"] != 0
  end
end
