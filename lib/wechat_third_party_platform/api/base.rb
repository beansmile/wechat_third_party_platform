require "httparty"
require "json"

module WechatThirdPartyPlatform
  class Base
    include HTTParty

    base_uri "https://api.weixin.qq.com"

    @@logger = ::Logger.new("./log/wechat_third_party_platform.log")

    HTTP_ERRORS = [
      EOFError,
      Errno::ECONNRESET,
      Errno::EINVAL,
      Net::HTTPBadResponse,
      Net::HTTPHeaderSyntaxError,
      Net::ProtocolError,
      Timeout::Error
    ]
  end
end
