# frozen_string_literal: true

class WechatThirdPartyPlatform::GenerateTrialVersionQrcodeJob < ApplicationJob
  def perform(submition)
    submition.generate_trial_version_qrcode!
  end
end
