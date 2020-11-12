# frozen_string_literal: true
module WechatThirdPartyPlatform::GrapeAPI::Entities
  class SimpleSubmition < Model
    expose :template_id
    expose :user_version
    expose :user_desc
    expose :state
    expose :application_id
    expose :reason
    expose_attached :trial_version_qrcode
  end
end
