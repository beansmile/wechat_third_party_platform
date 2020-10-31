# frozen_string_literal: true

class WechatThirdPartyPlatform::RefreshAccessTokenJob < ApplicationJob
  def perform(application)
    application.refresh_access_token
  end
end
