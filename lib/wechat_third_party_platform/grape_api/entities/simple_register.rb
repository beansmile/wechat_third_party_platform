# frozen_string_literal: true
module WechatThirdPartyPlatform::GrapeAPI::Entities
  class SimpleRegister < CustomGrape::Entity
    expose :name
    expose :code
    expose :code_type
    expose :legal_persona_wechat
    expose :legal_persona_name
    expose :state
  end
end
