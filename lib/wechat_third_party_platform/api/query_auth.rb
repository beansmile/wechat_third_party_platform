module WechatThirdPartyPlatform
  class QueryAuth < Base

    PRE_AUTH_CODE_CACHE_KEY = "wtpp_pre_auth_code"

    class << self
      def api_query_auth(auth_code)

        access_token = WechatThirdPartyPlatform::ComponentAccessToken.get

        body = {
          component_appid: WechatThirdPartyPlatform.appid,
          authorization_code: auth_code
        }

        resp = self.post("/cgi-bin/component/api_query_auth?component_access_token=#{access_token}", { body:  JSON.pretty_generate(body) })

        resp.parsed_response["authorization_info"]
      end
    end
  end
end
