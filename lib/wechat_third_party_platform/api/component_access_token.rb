module WechatThirdPartyPlatform
  class ComponentAccessToken < Base

    ACCESS_TOKEN_CACHE_KEY = "wtpp_access_token"

    class << self
      def get
        access_token = Rails.cache.fetch(ACCESS_TOKEN_CACHE_KEY)

        return access_token if access_token

        body = {
          component_appid: WechatThirdPartyPlatform.appid,
          component_appsecret: WechatThirdPartyPlatform.appsecret,
          component_verify_ticket: Rails.cache.fetch("wtpp_verify_ticket")
        }

        resp = self.post("/cgi-bin/component/api_component_token", { body:  JSON.pretty_generate(body) })

        token = resp.parsed_response["component_access_token"]

        Rails.cache.write(ACCESS_TOKEN_CACHE_KEY, token, expires_in: 115.minutes)

        token
      end
    end
  end
end
