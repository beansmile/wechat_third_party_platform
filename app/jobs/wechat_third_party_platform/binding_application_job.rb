# frozen_string_literal: true

class WechatThirdPartyPlatform::BindingApplicationJob < ApplicationJob
  def perform(application)
    application.set_base_data!
    application.set_default_domain!
  end
end
