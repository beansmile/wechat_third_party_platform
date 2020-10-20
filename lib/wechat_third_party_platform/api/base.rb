require "httparty"
require "json"

module WechatThirdPartyPlatform::API
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

    TIMEOUT = 5

    [:get, :post].each do |method|
      define_singleton_method "http_#{method}" do |path, options = {}, need_access_token = true|
        body = (options[:body] || {})
        headers = (options[:headers] || {}).reverse_merge({
          "Content-Type" => "application/json",
          "Accept-Encoding" => "*"
        })
        path = "#{path}?access_token=#{WechatThirdPartyPlatform::API::ComponentAccessToken.get}" if need_access_token

        uuid = SecureRandom.uuid

        @@logger.debug("request[#{uuid}]: method: #{method}, url: #{path}, body: #{body}, headers: #{headers}")

        response = begin
                     resp = self.class.send(method, path, body: JSON.pretty_generate(body), headers: headers, timeout: TIMEOUT).body
                     JSON.parse(resp)
                   rescue JSON::ParserError
                     resp
                   rescue *HTTP_ERRORS
                     { "errmsg" => "连接超时" }
                   end

        @@logger.debug("response[#{uuid}]: #{response}")

        response
      end
    end
  end
end
