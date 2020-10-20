module WechatThirdPartyPlatform::API
  class Code < Base
    class << self
      # https://developers.weixin.qq.com/doc/oplatform/Third-party_Platforms/Mini_Programs/code/commit.html
      def commit(template_id:, ext_json:, user_version:, user_desc:)
        http_post("/wxa/commit", body: {
          template_id: template_id,
          ext_json: ext_json,
          user_version: user_version,
          user_desc: user_desc
        })
      end
    end
  end
end
