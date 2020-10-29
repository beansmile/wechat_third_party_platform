# frozen_string_literal: true

class WechatThirdPartyPlatform::ReleaseJob < ApplicationJob
  queue_as :default

  def perform(application)
    application.release!
  end
end
