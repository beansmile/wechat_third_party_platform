# frozen_string_literal: true

module WechatThirdPartyPlatform::API
  module Wxacode
    # 获取无数量限制小程序码
    # https://developers.weixin.qq.com/doc/oplatform/Third-party_Platforms/Mini_Programs/qrcode/getwxacodeunlimit.html
    def getwxacodeunlimit(scene:, page: nil, width: nil, auto_color: nil, line_color: nil, is_hyaline: nil)
      http_post("/wxa/getwxacodeunlimit", body: {
        scene: scene,
        page: page,
        width: width,
        auto_color: auto_color,
        line_color: line_color,
        is_hyaline: is_hyaline
      })
    end

    # 获取有数量限制小程序码
    # https://developers.weixin.qq.com/doc/oplatform/Third-party_Platforms/Mini_Programs/qrcode/getwxacode.html
    def getwxacode(path:, width: nil, auto_color: nil, line_color: nil, is_hyaline: nil)
      http_post("/wxa/getwxacode", body: {
        page: page,
        width: width,
        auto_color: auto_color,
        line_color: line_color,
        is_hyaline: is_hyaline
      })
    end

    # 获取小程序二维码
    # https://developers.weixin.qq.com/doc/oplatform/Third-party_Platforms/Mini_Programs/qrcode/createwxaqrcode.html
    def createwxaqrcode(path:, width: nil)
      http_post("/cgi-bin/wxaapp/createwxaqrcode", body: {
        path: path,
        width: width
      })
    end
  end
end
