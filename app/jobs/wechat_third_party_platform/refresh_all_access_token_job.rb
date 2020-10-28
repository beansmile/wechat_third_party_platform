# frozen_string_literal: true

class WechatThirdPartyPlatform::RefreshAllAccessTokenJob < ApplicationJob
  queue_as :default

  def perform
    WechatThirdPartyPlatform::Application.find_each do |application|
      WechatThirdPartyPlatform::RefreshAccessTokenJob.perform_later(application)
    end
  end
end
