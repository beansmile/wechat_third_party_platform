# frozen_string_literal: true
module WechatThirdPartyPlatform::GrapeAPI::Entities
  class SimpleApplication < CustomGrape::Entity
    expose :appid
    expose :account_type
    expose :nick_name
    expose :user_name
    expose :principal_type
    expose :principal_name
    expose :source
  end
end
