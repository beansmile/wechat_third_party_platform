# frozen_string_literal: true

module WechatThirdPartyPlatform::API
  module Tester

    # 绑定微信用户为体验者
    # https://developers.weixin.qq.com/doc/oplatform/Third-party_Platforms/Mini_Programs/Admin.html
    def bind_tester(wechatid:)
      http_post("/wxa/bind_tester", body: { wechatid: wechatid })
    end

    # 获取体验者列表
    # https://developers.weixin.qq.com/doc/oplatform/Third-party_Platforms/Mini_Programs/memberauth.html
    def memberauth
      http_post("/wxa/memberauth", body: { action: "get_experiencer" })
    end

    # 解除绑定体验者
    # https://developers.weixin.qq.com/doc/oplatform/Third-party_Platforms/Mini_Programs/unbind_tester.html
    def unbind_tester(userstr:)
      http_post("/wxa/release", body: { userstr: userstr })
    end
  end
end
