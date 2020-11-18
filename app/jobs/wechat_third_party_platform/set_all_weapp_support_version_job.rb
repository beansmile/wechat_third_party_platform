# frozen_string_literal: true

class WechatThirdPartyPlatform::SetAllWeappSupportVersionJob < ApplicationJob
  def perform(application_ids, version)
    WechatThirdPartyPlatform::Application.where(id: application_ids).find_each do |application|
      WechatThirdPartyPlatform::SetWeappSupportVersionJob.perform_later(application, version)
    end
  end
end
