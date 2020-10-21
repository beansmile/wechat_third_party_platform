module WechatThirdPartyPlatform::API
  module AccountBaseInfo

    # 获取基本信息
    # https://developers.weixin.qq.com/doc/oplatform/Third-party_Platforms/Mini_Programs/Mini_Program_Information_Settings.html
    def getaccountbasicinfo
      http_get("/cgi-bin/account/getaccountbasicinfo")
    end
  end
end
