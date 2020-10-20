module WechatThirdPartyPlatform
  class PreauthCode < Base

    PRE_AUTH_CODE_CACHE_KEY = "wtpp_pre_auth_code"

    class << self
      # https://developers.weixin.qq.com/doc/oplatform/Third-party_Platforms/api/pre_auth_code.html
      def api_create_preauthcode

        pre_auth_code = Rails.cache.fetch(PRE_AUTH_CODE_CACHE_KEY)

        return pre_auth_code if pre_auth_code

        access_token = WechatThirdPartyPlatform::ComponentAccessToken.get

        body = {
          component_appid: WechatThirdPartyPlatform.appid,
        }

        resp = self.post("/cgi-bin/component/api_create_preauthcode?component_access_token=#{access_token}", { body:  JSON.pretty_generate(body) })

        pre_auth_code = resp.parsed_response["pre_auth_code"]

        Rails.cache.write(PRE_AUTH_CODE_CACHE_KEY, pre_auth_code, expires_in: 10.minutes)

        pre_auth_code
      end
    end
  end
end
