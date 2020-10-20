module WechatThirdPartyPlatform
  class AuthorizerInfo < Base

    class << self
      # https://developers.weixin.qq.com/doc/oplatform/Third-party_Platforms/api/api_get_authorizer_info.html
      def api_get_authorizer_info(appid)

        access_token = WechatThirdPartyPlatform::ComponentAccessToken.get

        body = {
          component_appid: WechatThirdPartyPlatform.appid,
          authorizer_appid: appid
        }

        resp = self.post("/cgi-bin/component/api_get_authorizer_info?component_access_token=#{access_token}", { body:  JSON.pretty_generate(body) })

        resp
      end
    end
  end
end
