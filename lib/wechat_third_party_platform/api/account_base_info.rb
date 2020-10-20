module WechatThirdPartyPlatform::API
  class AccountBaseInfo < Base

    class << self
      # https://developers.weixin.qq.com/doc/oplatform/Third-party_Platforms/Mini_Programs/Mini_Program_Information_Settings.html
      def getaccountbasicinfo(authorizer_access_token)

        resp = self.get("/cgi-bin/account/getaccountbasicinfo?access_token=#{authorizer_access_token}")

        resp.parsed_response
      end
    end
  end
end
