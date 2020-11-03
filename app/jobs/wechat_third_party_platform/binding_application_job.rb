# frozen_string_literal: true

class WechatThirdPartyPlatform::BindingApplicationJob < ApplicationJob
  def perform(application)
    application.set_default_domain!
    application.set_base_data!
  end
end
