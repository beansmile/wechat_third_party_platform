# frozen_string_literal: true

module WechatThirdPartyPlatform::GrapeAPI
  class AccessToken < Grape::API
    namespace "wechat_third_party_platform/applications" do
      desc "获取access token", summary: "获取access token"
      params do
        requires :appid
      end
      get "access_token" do
        if request.headers["Api-Authorization-Token"] != Rails.application.credentials.dig(Rails.env.to_sym, WechatThirdPartyPlatform::Application.api_authorization_token_key)
          error!({ error_message: "401 Unauthorized" }, 401)
        end

        { access_token: WechatThirdPartyPlatform::Application.find_by!(appid: params[:appid]).access_token }
      end
    end
  end
end
