 # frozen_string_literal: true

module WechatThirdPartyPlatform
  module AccessTokenConcern
    extend ActiveSupport::Concern

    ENV_FALLBACK_ARRAY = [[:production, :staging], [:development]]

    def self.included(klass)
      klass.instance_eval do
        def self.api_authorization_token_key
          :api_authorization_token
        end
      end
    end

    def host_key
      :host
    end

    def update_access_token
      update!(access_token: get_access_token)
    end

    # 正式环境和测试环境绑定的是不同的小程序，所以可以刷新access_token
    # development环境获取access_token时，先去production获取，没获取到的话就去staing获取
    def get_access_token
      token = access_token
      ENV_FALLBACK_ARRAY.each do |env_array|
        if Rails.env.to_sym.in?(env_array)
          break
        else
          env_array.each do |env|
            host = Rails.application.credentials.dig(env, host_key)

            # 未部署的环境暂时不配置host
            next if host.blank?

            resp = HTTParty.get("#{host}/admin_api/v1/wechat_third_party_platform/applications/access_token?appid=#{appid}", headers: { "api-authorization-token" => Rails.application.credentials.dig(env, self.class.api_authorization_token_key) })
            next unless token = resp["access_token"]

            break
          end
        end
      end
      token
    end

    # 没授权成功（即没绑定成功）的小程序不可刷新access_token
    def can_refresh_access_token?
      ENV_FALLBACK_ARRAY.each do |env_array|
        if env_array.any? { |env| Rails.application.credentials.dig(env, host_key) }
          return Rails.env.to_sym.in?(env_array) && refresh_token.present? && project_application.present? && !authorizer_unauthorized?
        end
      end
    end

    def refresh_access_token
      if can_refresh_access_token?
        resp = WechatThirdPartyPlatform.refresh_authorizer_access_token(authorizer_appid: appid, authorizer_refresh_token: refresh_token)
        update!(access_token: resp["authorizer_access_token"], refresh_token: resp["authorizer_refresh_token"])
      end
    end
  end
end
