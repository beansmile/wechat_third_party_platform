# frozen_string_literal: true

class WechatThirdPartyPlatform::SetUnlimitedWxacodeJob < ApplicationJob
  def perform(resource, column)
    resource.send("set_#{column}_with_unlimited_wxacode")
  end
end
