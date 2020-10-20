require "wechat_third_party_platform/engine"
require "wechat_third_party_platform/message_encryptor"
require "wechat_third_party_platform/api"

module WechatThirdPartyPlatform
  class<< self
    attr_accessor :appid, :appsecret, :message_token, :message_key, :auth_redirect_url
  end
end
