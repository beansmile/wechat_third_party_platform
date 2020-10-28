# frozen_string_literal: true

class WechatThirdPartyPlatform::ApplicationSetBaseDataJob < ApplicationJob
  queue_as :default

  def perform(application)
    application.set_base_data
  end
end
