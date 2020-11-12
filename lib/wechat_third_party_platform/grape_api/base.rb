# frozen_string_literal: true
module WechatThirdPartyPlatform::GrapeAPI
  class Base < Grape::API
    include Grape::Kaminari

    namespace "wechat_third_party_platform/base" do
      desc "小程序授权页面URL"
      paginate
      get "component_auth_url" do
        if current_application
          { url: WechatThirdPartyPlatform.component_auth_url(application_id: current_application.id) }
        else
          response_error("只有关联了应用的用户可以立即绑定小程序")
        end
      end
    end
  end
end
