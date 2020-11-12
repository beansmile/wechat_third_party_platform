# frozen_string_literal: true
module WechatThirdPartyPlatform::GrapeAPI::Entities
  class Application < SimpleApplication
    expose_attached :head_img
    expose_attached :qrcode_url
    expose :trial_submition, using: SimpleSubmition
    expose :audit_submition, using: SimpleSubmition
    expose :online_submition, using: SimpleSubmition
  end
end
