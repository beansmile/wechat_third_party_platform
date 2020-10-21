# frozen_string_literal: true

require "httparty"

module WechatThirdPartyPlatform
  class Client
    include HTTParty
    include WechatThirdPartyPlatform::API::AccountBaseInfo
    include WechatThirdPartyPlatform::API::Code

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

    attr_accessor :access_token

    def initialize(access_token)
      @access_token = access_token
    end

    [:get, :post].each do |method|
      define_method "http_#{method}" do |path, options = {}, need_access_token = true|
        body = (options[:body] || {})
        headers = (options[:headers] || {}).reverse_merge({
          "Content-Type" => "application/json",
          "Accept-Encoding" => "*"
        })
        path = "#{path}?access_token=#{access_token}" if need_access_token

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
