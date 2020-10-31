# frozen_string_literal: true

class WechatThirdPartyPlatform::ReleaseJob < ApplicationJob
  def perform(application)
    application.release!
  end
end
