# frozen_string_literal: true

class WechatThirdPartyPlatform::ThirdFasteregisterJob < ApplicationJob
  def perform(register, auth_code)
    register.generate_application!(auth_code: auth_code)
  end
end
