# frozen_string_literal: true

module WechatThirdPartyPlatform::API
  module AccountBaseInfo

    # 获取基本信息
    # https://developers.weixin.qq.com/doc/oplatform/Third-party_Platforms/Mini_Programs/Mini_Program_Information_Settings.html
    def getaccountbasicinfo
      http_get("/cgi-bin/account/getaccountbasicinfo")
    end

    # 设置服务器域名
    # https://developers.weixin.qq.com/doc/oplatform/Third-party_Platforms/Mini_Programs/Server_Address_Configuration.html
    def modify_domain(action:, requestdomain: nil, wsrequestdomain: nil, uploaddomain: nil, downloaddomain: nil)
      body = {
        action: action,
        requestdomain: requestdomain,
        wsrequestdomain: wsrequestdomain,
        uploaddomain: uploaddomain,
        downloaddomain: downloaddomain
      }
      http_post("/wxa/modify_domain", body: body)
    end

    # 设置业务域名
    # https://developers.weixin.qq.com/doc/oplatform/Third-party_Platforms/Mini_Programs/setwebviewdomain.html
    def setwebviewdomain(action: nil, webviewdomain: nil)
      http_post("/wxa/setwebviewdomain", body: {
        action: action,
        webviewdomain: webviewdomain,
      })
    end

    # 设置名称
    # https://developers.weixin.qq.com/doc/oplatform/Third-party_Platforms/Mini_Programs/setnickname.html
    def setnickname(nick_name:, id_card: nil, license: nil, naming_other_stuff_1: nil, naming_other_stuff_2: nil, naming_other_stuff_3: nil, naming_other_stuff_4: nil, naming_other_stuff_5: nil)
      http_post("/wxa/setnickname", body: {
        action: nick_name,
        id_card: id_card,
        license: license,
        naming_other_stuff_1: naming_other_stuff_1,
        naming_other_stuff_2: naming_other_stuff_2,
        naming_other_stuff_3: naming_other_stuff_3,
        naming_other_stuff_4: naming_other_stuff_4,
        naming_other_stuff_5: naming_other_stuff_5
      })
    end

    # 微信认证名称检测
    # https://developers.weixin.qq.com/doc/oplatform/Third-party_Platforms/Mini_Programs/wxverify_checknickname.html
    def checkwxverifynickname(nick_name:)
      http_post("/cgi-bin/wxverify/checkwxverifynickname", body: {
        nick_name: nick_name
      })
    end

    # 修改头像
    # https://developers.weixin.qq.com/doc/oplatform/Third-party_Platforms/Mini_Programs/modifyheadimage.html
    def modifyheadimage(head_img_media_id:, x1:, y1:, x2:, y2:)
      http_post("/cgi-bin/account/modifyheadimage", body: {
        head_img_media_id: head_img_media_id,
        x1: x1,
        y1: y1,
        x2: x2,
        y2: y2
      })
    end

    # 修改功能介绍
    # https://developers.weixin.qq.com/doc/oplatform/Third-party_Platforms/Mini_Programs/modifysignature.html
    def modifysignature(signature:)
      http_post("/cgi-bin/account/modifysignature", body: {
        signature: signature
      })
    end
  end
end
