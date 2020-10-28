 # frozen_string_literal: true

module WechatThirdPartyPlatform
  module AccessTokenConcern
    extend ActiveSupport::Concern
    include HTTParty

    ENV_FALLBACK_ARRAY = [:productino, :staging, :development]

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

    def get_access_token
      ENV_FALLBACK_ARRAY.each do |env|
        if Rails.env == env.to_s
          break
        else
          host = Rails.application.credentials.dig(env, host_key)

          # 未部署的环境暂时不配置host
          next if host.blank?

          resp = self.class.get("#{host}/app_api/v1/bean/applications/#{appid}/access_token",
            headers: { "api-authorization-token" => Rails.application.credentials.dig(env, self.class.api_authorization_token_key) })

          next unless access_token = resp["access_token"]
        end
      end

      access_token
    end

    # 只有正式环境可以刷新access_token, 未部署正式前只有测试环境可以刷新
    def can_refresh_access_token?
      ENV_FALLBACK_ARRAY.each do |env|
        return !!(Rails.env.send("#{env}?") && refresh_token) if Rails.application.credentials.dig(env, host_key)
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
