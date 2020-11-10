# frozen_string_literal: true

module WechatThirdPartyPlatform::API
  module Auth
    # https://developers.weixin.qq.com/miniprogram/dev/api-backend/open-api/login/auth.code2Session.html
    # 登录凭证校验。通过 wx.login 接口获得临时登录凭证 code 后传到开发者服务器调用此接口完成登录流程
    def code_to_session(code:)
      body = {
        appid: appid,
        js_code: code,
        component_appid: WechatThirdPartyPlatform.component_appid,
        component_access_token: WechatThirdPartyPlatform.get_component_access_token,
        grant_type: "authorization_code"
      }

      http_get("/sns/component/jscode2session?#{body.to_query}", {}, need_access_token: false)
    end
  end
end
