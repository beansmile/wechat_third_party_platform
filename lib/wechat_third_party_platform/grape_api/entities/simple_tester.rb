# frozen_string_literal: true
module WechatThirdPartyPlatform::GrapeAPI::Entities
  class SimpleTester < CustomGrape::Entity
    expose :wechat_id
    expose :userstr
  end
end
