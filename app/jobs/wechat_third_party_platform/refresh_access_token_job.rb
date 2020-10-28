# frozen_string_literal: true

class WechatThirdPartyPlatform::RefreshAccessTokenJob < ApplicationJob
  queue_as :default

  def perform(application)
    application.refresh_access_token
  end
end
